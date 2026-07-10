import 'package:flutter/material.dart';

enum SortDirection { ascending, descending }

/// A Range-like class that works for inclusive ranges of lines in source code.
class LineRange {
  const LineRange(this.begin, this.end) : assert(begin <= end);

  final int begin;
  final int end;

  int get size => end - begin + 1;

  bool contains(num target) => target >= begin && target <= end;

  @override
  String toString() => 'LineRange($begin, $end)';

  @override
  bool operator ==(Object other) {
    if (other is! LineRange) return false;
    return begin == other.begin && end == other.end;
  }

  @override
  int get hashCode => Object.hash(begin, end);
}

extension SortDirectionExtension on SortDirection {
  SortDirection reverse() {
    return this == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
  }
}

extension ColorSchemeBrightnessExtension on ColorScheme {
  bool get isLight => brightness == Brightness.light;
}
