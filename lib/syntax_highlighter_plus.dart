import 'package:flutter/widgets.dart';

import 'src/grammar_registry.dart';
import 'src/syntax_highlighter.dart';
import 'src/theme_registry.dart';

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
  /// Returns the list of supported languages.
  static List<String> get supportedLanguages => GrammarRegistry.supportedLanguages;

  /// Returns the list of supported themes.
  static List<String> get supportedThemes => ThemeRegistry.supportedThemes;

  /// The theme to use for highlighting (e.g. `'github-dark'`).
  final String theme;

  /// Creates a highlighter that applies [theme] when rendering.
  ///
  /// [theme] must be a supported theme id (e.g. `'github-dark'`). Check
  /// [SyntaxHighlighterPlus.supportedThemes].
  const SyntaxHighlighterPlus({required this.theme});

  // -------------------------------------------------------------------------
  // Highlighting
  // -------------------------------------------------------------------------

  /// Highlights [source] and returns the result as a [TextSpan].
  ///
  /// * [language] — language id (e.g. `'dart'`). Must be a supported grammar id or alias. Check [SyntaxHighlighterPlus.supportedLanguages].
  /// * [lineRange] — optional subset of lines to highlight.
  ///
  /// Colors are driven by the [theme] passed to the constructor.
  Future<TextSpan> highlight(
    String language,
    String source,
  ) async {
    final syntaxTheme = await ThemeRegistry.themeFor(theme);
    final grammar = await GrammarRegistry.grammarFor(language);

    final syntaxHighlighter = SyntaxHighlighter(grammar: grammar, source: source);
    return syntaxHighlighter.highlight(theme: syntaxTheme);
  }
}
