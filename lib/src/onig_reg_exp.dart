import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'oniguruma_bindings_generated.dart';

class _StringCache {
  static String? _lastString;
  static ffi.Pointer<ffi.Uint16>? _lastPtr;

  static ffi.Pointer<ffi.Uint16> get(String string) {
    if (_lastString == string) return _lastPtr!;
    if (_lastPtr != null) calloc.free(_lastPtr!);
    _lastString = string;
    final codeUnits = string.codeUnits;
    _lastPtr = calloc<ffi.Uint16>(codeUnits.length);
    _lastPtr!.asTypedList(codeUnits.length).setAll(0, codeUnits);
    return _lastPtr!;
  }
}

class OnigMatch {
  final List<int> _begs;
  final List<int> _ends;

  OnigMatch(this._begs, this._ends);

  int get start => _begs.isNotEmpty ? _begs[0] : 0;
  int get end => _ends.isNotEmpty ? _ends[0] : 0;
  int get groupCount => _begs.length - 1;

  int groupStart(int group) {
    if (group < 0 || group >= _begs.length) return -1;
    return _begs[group];
  }

  int groupEnd(int group) {
    if (group < 0 || group >= _ends.length) return -1;
    return _ends[group];
  }
}

class OnigRegExp {
  static OnigurumaBindings? _bindings;
  static bool _initialized = false;
  static late final ffi.DynamicLibrary dylib;
  static late final ffi.Pointer<OnigEncodingType> _encoding;

  static OnigurumaBindings get bindings {
    if (_bindings == null) {
      final String libraryName;
      if (Platform.isMacOS || Platform.isIOS) {
        libraryName = 'syntax_highlighter_plus.framework/syntax_highlighter_plus';
      } else if (Platform.isWindows) {
        libraryName = 'syntax_highlighter_plus.dll';
      } else {
        libraryName = 'libsyntax_highlighter_plus.so';
      }

      if (Platform.isIOS || Platform.isMacOS) {
        try {
          dylib = ffi.DynamicLibrary.open(libraryName);
        } catch (_) {
          dylib = ffi.DynamicLibrary.process();
        }
      } else {
        dylib = ffi.DynamicLibrary.open(libraryName);
      }

      _bindings = OnigurumaBindings(dylib);
      _encoding = dylib.lookup<OnigEncodingType>('OnigEncodingUTF16_LE');
    }
    return _bindings!;
  }

  static void initialize() {
    if (!_initialized) {
      bindings.onig_initialize(ffi.nullptr, 0);
      _initialized = true;
    }
  }

  late ffi.Pointer<re_pattern_buffer> _regex;
  bool _isDisposed = false;

  OnigRegExp(String pattern) {
    initialize();

    final regPtr = calloc<ffi.Pointer<re_pattern_buffer>>();
    final errorInfo = calloc<OnigErrorInfo>();

    final patternUtf16 = pattern.codeUnits;
    final ptr = calloc<ffi.Uint16>(patternUtf16.length);
    ptr.asTypedList(patternUtf16.length).setAll(0, patternUtf16);

    final patternStart = ptr.cast<ffi.UnsignedChar>();
    final patternEnd = ffi.Pointer<ffi.UnsignedChar>.fromAddress(patternStart.address + (patternUtf16.length * 2));

    try {
      final syntax = dylib.lookup<ffi.Pointer<OnigSyntaxType>>('OnigDefaultSyntax').value;

      final r = bindings.onig_new(
        regPtr,
        patternStart,
        patternEnd,
        0,
        _encoding,
        syntax,
        errorInfo,
      );

      if (r != 0) {
        throw FormatException('Oniguruma regex error code: $r', pattern);
      }
      _regex = regPtr.value;
    } finally {
      calloc.free(ptr);
      calloc.free(regPtr);
      calloc.free(errorInfo);
    }
  }

  void dispose() {
    if (!_isDisposed) {
      bindings.onig_free(_regex);
      _isDisposed = true;
    }
  }

  OnigMatch? search(String string, int start) {
    if (_isDisposed) throw StateError('Regex is disposed');

    final strPtr = _StringCache.get(string);
    final strStart = strPtr.cast<ffi.UnsignedChar>();
    final strEnd = ffi.Pointer<ffi.UnsignedChar>.fromAddress(strStart.address + (string.length * 2));
    final searchStart = ffi.Pointer<ffi.UnsignedChar>.fromAddress(strStart.address + (start * 2));

    final region = bindings.onig_region_new();

    try {
      final r = bindings.onig_search(
        _regex,
        strStart,
        strEnd,
        searchStart,
        strEnd,
        region,
        0,
      );

      if (r >= 0) {
        final numRegs = region.ref.num_regs;
        final begs = <int>[];
        final ends = <int>[];
        for (var i = 0; i < numRegs; i++) {
          final b = region.ref.beg[i];
          final e = region.ref.end[i];
          begs.add(b < 0 ? -1 : b ~/ 2);
          ends.add(e < 0 ? -1 : e ~/ 2);
        }
        return OnigMatch(begs, ends);
      } else {
        return null;
      }
    } finally {
      bindings.onig_region_free(region, 1);
    }
  }
}
