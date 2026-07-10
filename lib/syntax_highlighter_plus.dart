import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'span_parser.dart';
import 'syntax_highlighter.dart';
import 'syntax_theme.dart';
import 'utils.dart';

/// Languages with bundled TextMate grammar support.
enum SupportedLanguage {
  dart('dart'),
  swift('swift');

  const SupportedLanguage(this.id);

  /// The grammar file name (without extension) under `assets/grammars/`.
  final String id;
}

/// Bundled color themes.
enum SupportedTheme {
  githubDark('github-dark'),
  githubLight('github-light');

  const SupportedTheme(this.id);

  /// The theme file name (without extension) under `assets/themes/`.
  final String id;
}

/// High-level syntax-highlighting helper.
///
/// Create one instance per desired theme and reuse it; grammars and themes
/// are both cached statically so repeated calls are cheap.
///
/// ```dart
/// final highlighter = SyntaxHighlighterPlus(theme: 'github-dark');
/// final span = await highlighter.highlight('dart', _source);
/// ```
class SyntaxHighlighterPlus {
  /// Creates a highlighter that applies [theme] when rendering.
  ///
  /// [theme] must be one of the [SupportedTheme] ids (e.g. `'github-dark'`),
  /// or `null` to produce unstyled plain-text spans.
  const SyntaxHighlighterPlus({this.theme});

  /// The theme to use for highlighting (e.g. `'github-dark'`).
  ///
  /// Must be a [SupportedTheme] id, or `null` for unstyled output.
  final String? theme;

  // -------------------------------------------------------------------------
  // Static grammar loader
  // -------------------------------------------------------------------------

  static final Map<String, Grammar> _grammarCache = {};

  /// Returns the [Grammar] for [language], loading and parsing it from the
  /// bundled asset the first time it is requested.
  ///
  /// Throws an [ArgumentError] if [language] does not match any bundled grammar.
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

  // -------------------------------------------------------------------------
  // Static theme loader
  // -------------------------------------------------------------------------

  /// Returns the [SyntaxTheme] for [themeName], loading and parsing it from
  /// the bundled asset the first time it is requested.
  ///
  /// [themeName] must be a [SupportedTheme] id (e.g. `'github-dark'`), or an
  /// [ArgumentError] is thrown.
  ///
  /// Results are cached so subsequent calls are instant.
  static Future<SyntaxTheme> themeFor(String themeName) async {
    final normalized = themeName.toLowerCase().trim();
    final supported = SupportedTheme.values.map((e) => e.id).toSet();
    if (!supported.contains(normalized)) {
      throw ArgumentError(
        'No bundled theme for "$themeName". '
        'Supported themes: ${supported.join(', ')}.',
      );
    }
    return SyntaxTheme.load(normalized);
  }

  // -------------------------------------------------------------------------
  // Highlighting
  // -------------------------------------------------------------------------

  /// Highlights [source] and returns the result as a [TextSpan].
  ///
  /// * [language] — language id (e.g. `'dart'`). Must be a [SupportedLanguage].
  /// * [lineRange] — optional subset of lines to highlight.
  ///
  /// Colors are driven by the [theme] passed to the constructor. When [theme]
  /// is `null` the returned spans carry no color information.
  Future<TextSpan> highlight(
    String language,
    String source, {
    LineRange? lineRange,
  }) async {
    final grammar = await grammarFor(language);
    final syntaxHighlighter = SyntaxHighlighter(
      grammar: grammar,
      source: source,
    );

    final syntaxTheme = theme != null ? await themeFor(theme!) : null;
    return syntaxHighlighter.highlight(
      theme: syntaxTheme,
      lineRange: lineRange,
    );
  }
}
