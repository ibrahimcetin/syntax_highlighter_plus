// Copyright 2021 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'span_parser.dart';
import 'syntax_theme.dart';
import 'utils.dart';

class SyntaxHighlighter {
  SyntaxHighlighter({required this.grammar, required this.source});

  final Grammar grammar;

  final String source;
  late String _processedSource;

  final _spanStack = ListQueue<ScopeSpan>();

  int _currentPosition = 0;

  SyntaxTheme? _syntaxTheme;

  /// Returns the highlighted [source] in [TextSpan] form.
  ///
  /// Pass a [theme] to apply colors from a [SyntaxTheme]. When [theme] is
  /// `null` all spans are unstyled (plain text).
  ///
  /// If [lineRange] is provided, only the lines between
  /// `[lineRange.begin, lineRange.end]` will be returned.
  TextSpan highlight({SyntaxTheme? theme, LineRange? lineRange}) {
    _syntaxTheme = theme;
    _currentPosition = 0;
    _processedSource = source;
    if (lineRange != null) {
      _processedSource = _processedSource
          .split('\n') //
          .sublist(lineRange.begin - 1, lineRange.end)
          .join('\n');
    }
    return TextSpan(
      children: _highlightLoopHelper(
        currentScope: null,
        loopCondition: () => _currentPosition < _processedSource.length,
        scopes: SpanParser.parse(grammar, _processedSource),
      ),
    );
  }

  /// Returns the [TextStyle] for the current span based on the current scopes.
  ///
  /// If there are multiple scopes for a span, styling for each scope is
  /// applied in the order the scopes are listed (i.e., later scope styles take
  /// precedence).
  TextStyle _getStyleForSpan() {
    if (_spanStack.isEmpty) return const TextStyle();
    final scopes = _spanStack.last.scopes;
    if (scopes.isEmpty) return const TextStyle();

    var style = const TextStyle();
    for (final scope in scopes) {
      style = style.merge(_resolveScope(scope));
    }
    return style;
  }

  /// Resolves a single TextMate [scope] to a [TextStyle] using the active
  /// [SyntaxTheme]. Returns an empty [TextStyle] when no theme is set or no
  /// rule matches the scope.
  TextStyle _resolveScope(String scope) {
    return _syntaxTheme?.resolveStyle(scope) ?? const TextStyle();
  }

  /// Enters a new scope for a span of text. Returns a [List<TextSpan>]
  /// containing the stylized text from within the scope.
  List<TextSpan> _scope(ScopeSpan currentScope, List<ScopeSpan> scopes) {
    return _highlightLoopHelper(
      currentScope: currentScope,
      loopCondition: () => currentScope.contains(_currentPosition),
      scopes: scopes,
    );
  }

  List<TextSpan> _highlightLoopHelper({
    required ScopeSpan? currentScope,
    required bool Function() loopCondition,
    required List<ScopeSpan> scopes,
  }) {
    final sourceSpans = <TextSpan>[];
    int? currentScopeBegin = _currentPosition;
    if (currentScope != null) {
      _spanStack.addLast(currentScope);
    }
    while (loopCondition()) {
      if (scopes.isNotEmpty && scopes.first.contains(_currentPosition)) {
        // Encountered the next scoped span. Close the current span and enter
        // the next.
        final text = _processedSource.substring(
          currentScopeBegin!,
          _currentPosition,
        );
        if (text.isNotEmpty) {
          sourceSpans.add(TextSpan(style: _getStyleForSpan(), text: text));
        }
        sourceSpans.addAll(_scope(scopes.removeAt(0), scopes));
        // Reset the beginning of the current span to the first position after
        // the close of the span that was just processed.
        currentScopeBegin = _currentPosition;
      } else if (_atNewline()) {
        currentScopeBegin = _processNewlines(sourceSpans, currentScopeBegin!);
      } else {
        ++_currentPosition;
      }
    }
    // Reached the end of the text covered by the current span. Close the span
    // and exit the scope.
    final text = _processedSource.substring(
      currentScopeBegin!,
      _currentPosition,
    );
    if (text.isNotEmpty) {
      sourceSpans.add(TextSpan(style: _getStyleForSpan(), text: text));
    }
    if (currentScope != null) {
      _spanStack.removeLast();
    }
    return sourceSpans;
  }

  bool _atNewline() => String.fromCharCode(_processedSource.codeUnitAt(_currentPosition)) == '\n';

  int? _processNewlines(List<TextSpan> sourceSpans, int currentScopeBegin) {
    final text = _processedSource.substring(
      currentScopeBegin,
      _currentPosition,
    );
    if (text.isNotEmpty) {
      sourceSpans.add(
        TextSpan(
          style: _getStyleForSpan(),
          text: _processedSource.substring(currentScopeBegin, _currentPosition),
        ),
      );
    }
    // We artificially break up spans if they contain a newline so it's easier
    // to find line boundaries when we try and populate the code view.
    do {
      sourceSpans.add(const TextSpan(text: '\n'));
      ++_currentPosition;
    } while ((_currentPosition < _processedSource.length) &&
        (String.fromCharCode(_processedSource.codeUnitAt(_currentPosition)) == '\n'));
    return _currentPosition;
  }
}
