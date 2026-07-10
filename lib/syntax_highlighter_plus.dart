import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'span_parser.dart';
import 'syntax_highlighter.dart';

/// Languages with bundled TextMate grammar support.
enum SupportedLanguage {
  dart('dart'),
  swift('swift');

  const SupportedLanguage(this.id);

  /// The grammar file name (without extension) under `assets/grammars/`.
  final String id;
}

class SyntaxHighlighterPlus {
  /// Cache so each grammar JSON is only parsed once per app lifecycle.
  static final Map<String, Grammar> _grammarCache = {};

  /// Returns the [Grammar] for [language], loading and parsing it from the
  /// bundled asset the first time it is requested.
  ///
  /// Throws an [ArgumentError] if [language] does not match any bundled grammar.
  ///
  /// Example:
  /// ```dart
  /// final grammar = await SyntaxHighlighterPlus.grammarFor('dart');
  /// ```
  static Future<Grammar> grammarFor(String language) async {
    final normalized = language.toLowerCase().trim();

    // Return from cache if already loaded.
    if (_grammarCache.containsKey(normalized)) {
      return _grammarCache[normalized]!;
    }

    // Validate against the known set of bundled grammars.
    final supported = SupportedLanguage.values.map((e) => e.id).toSet();
    if (!supported.contains(normalized)) {
      throw ArgumentError(
        'No bundled grammar for "$language". '
        'Supported languages: ${supported.join(', ')}.',
      );
    }

    final jsonString = await rootBundle.loadString(
      'packages/syntax_highlighter_plus/assets/grammars/$normalized.json',
    );

    final grammar = Grammar.fromJson(
      jsonDecode(jsonString) as Map<String, Object?>,
    );

    _grammarCache[normalized] = grammar;
    return grammar;
  }

  Future<TextSpan> highlight(
    BuildContext context,
    String source,
    String language,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final syntaxHighlighter = SyntaxHighlighter.withGrammar(
      source: source,
      grammar: await grammarFor(language),
    );
    return syntaxHighlighter.highlight(colorScheme);
  }
}
