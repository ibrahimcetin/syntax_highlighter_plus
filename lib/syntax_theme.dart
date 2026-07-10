import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// A parsed TextMate / VS Code color theme.
///
/// Use [SyntaxTheme.load] to load one of the bundled themes by name, or
/// [SyntaxTheme.fromJson] to parse your own JSON map.
///
/// Pass a [SyntaxTheme] to [SyntaxHighlighter.highlight] to apply its colors
/// instead of the default [ColorScheme]-derived palette.
class SyntaxTheme {
  SyntaxTheme._({
    required this.name,
    required this.displayName,
    required this.type,
    required this.editorBackground,
    required this.editorForeground,
    required this.tokenRules,
  });

  // -------------------------------------------------------------------------
  // Fields
  // -------------------------------------------------------------------------

  /// Machine-readable theme identifier (e.g. `'github-dark'`).
  final String name;

  /// Human-readable display name (e.g. `'GitHub Dark'`).
  final String displayName;

  /// `'dark'` or `'light'`, taken from the `type` field in the theme JSON.
  final String type;

  /// Background color for the editor area (`colors.editor.background`).
  /// May be `null` if the theme JSON omits this key.
  final Color? editorBackground;

  /// Default foreground color for un-highlighted text (`colors.editor.foreground`).
  /// May be `null` if the theme JSON omits this key.
  final Color? editorForeground;

  /// Ordered list of token-color rules parsed from `tokenColors`.
  ///
  /// Rules are applied in order; a later rule for the *same* scope does **not**
  /// override an earlier one — instead the first (most-specific) match wins.
  final List<TokenColorRule> tokenRules;

  bool get isDark => type == 'dark';

  // -------------------------------------------------------------------------
  // Parsing
  // -------------------------------------------------------------------------

  /// Parses a theme from a decoded JSON [map].
  ///
  /// [themeName] is the machine-readable identifier (used as [name]).
  factory SyntaxTheme.fromJson(String themeName, Map<String, Object?> map) {
    final colors = (map['colors'] as Map<String, Object?>?) ?? {};
    final editorBg = _parseColor(colors['editor.background'] as String?);
    final editorFg = _parseColor(colors['editor.foreground'] as String?);

    final rawRules = (map['tokenColors'] as List<Object?>?) ?? [];
    final rules = <TokenColorRule>[];
    for (final raw in rawRules) {
      final entry = raw as Map<String, Object?>;
      final rule = TokenColorRule._fromJson(entry);
      if (rule != null) rules.add(rule);
    }

    return SyntaxTheme._(
      name: themeName,
      displayName: (map['displayName'] as String?) ?? themeName,
      type: (map['type'] as String?) ?? 'dark',
      editorBackground: editorBg,
      editorForeground: editorFg,
      tokenRules: rules,
    );
  }

  // -------------------------------------------------------------------------
  // Scope resolution
  // -------------------------------------------------------------------------

  /// Returns the merged [TextStyle] for a token with scope [tokenScope].
  ///
  /// Rules are iterated in order. For each rule, we check whether any of its
  /// declared scopes *prefix-matches* the [tokenScope] (TextMate selector
  /// semantics). The most specific prefix match (longest match) wins.
  ///
  /// Compound selectors such as `"string variable"` are supported: every word
  /// is matched in order against the dot-delimited segments of [tokenScope].
  ///
  /// Returns `null` when no rule matches (caller should use a default style).
  TextStyle? resolveStyle(String tokenScope) {
    TokenColorRule? bestRule;
    int bestScore = -1;

    for (final rule in tokenRules) {
      for (final ruleScope in rule.scopes) {
        final score = _matchScore(ruleScope, tokenScope);
        if (score > bestScore) {
          bestScore = score;
          bestRule = rule;
        }
      }
    }

    return bestRule?.toTextStyle();
  }

  /// Returns a score ≥ 0 if [ruleScope] matches [tokenScope], or -1 if not.
  ///
  /// Higher scores mean more specific matches.
  ///
  /// ### Simple prefix matching
  /// `"keyword"` matches `"keyword.control.dart"` with score = 1 (1 segment).
  /// `"keyword.control"` matches `"keyword.control.dart"` with score = 2.
  ///
  /// ### Compound / descendant selectors
  /// `"string variable"` is space-separated; every word must appear as a
  /// prefix of one of the dot-segments of [tokenScope] in order.
  /// We implement a simplified version: each word must prefix-match a
  /// dot-segment within [tokenScope]. Score = number of matched words.
  static int _matchScore(String ruleScope, String tokenScope) {
    final words = ruleScope.trim().split(RegExp(r'\s+'));
    final tokenSegments = tokenScope.split('.');

    if (words.length == 1) {
      // Simple prefix: tokenScope must start with ruleScope (segment-aligned).
      final prefix = words.first;
      if (tokenScope == prefix || tokenScope.startsWith('$prefix.')) {
        // Score = number of segments in the matching prefix.
        return prefix.split('.').length;
      }
      return -1;
    }

    // Compound selector — each word must match a token segment as a prefix,
    // in order (left to right).
    int segIdx = 0;
    int matchedWords = 0;
    for (final word in words) {
      bool found = false;
      while (segIdx < tokenSegments.length) {
        if (tokenSegments[segIdx].startsWith(word) || //
            word.contains('.') && tokenScope.startsWith(word)) {
          segIdx++;
          found = true;
          break;
        }
        segIdx++;
      }
      if (!found) return -1;
      matchedWords++;
    }
    return matchedWords;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Parses a hex color string like `'#f97583'` or `'#fff'`.
  /// Returns `null` for `null` input or unrecognised formats.
  static Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final h = hex.trim().replaceFirst('#', '');
    if (h.length == 3) {
      // Expand short form: 'abc' → 'aabbcc'
      final r = int.tryParse(h[0] * 2, radix: 16);
      final g = int.tryParse(h[1] * 2, radix: 16);
      final b = int.tryParse(h[2] * 2, radix: 16);
      if (r == null || g == null || b == null) return null;
      return Color.fromARGB(255, r, g, b);
    }
    if (h.length == 6) {
      final v = int.tryParse(h, radix: 16);
      if (v == null) return null;
      return Color(0xFF000000 | v);
    }
    if (h.length == 8) {
      // RRGGBBAA
      final v = int.tryParse(h, radix: 16);
      if (v == null) return null;
      final r = (v >> 24) & 0xFF;
      final g = (v >> 16) & 0xFF;
      final b = (v >> 8) & 0xFF;
      final a = v & 0xFF;
      return Color.fromARGB(a, r, g, b);
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// TokenColorRule
// ---------------------------------------------------------------------------

/// A single rule from the `tokenColors` array of a theme JSON.
class TokenColorRule {
  const TokenColorRule._({
    required this.scopes,
    this.foreground,
    this.background,
    this.fontStyle,
    this.fontWeight,
    this.decoration,
  });

  /// The TextMate scope selectors this rule applies to.
  final List<String> scopes;

  /// Foreground text color, or `null` if unset.
  final Color? foreground;

  /// Background highlight color, or `null` if unset.
  final Color? background;

  /// Italic / normal font style, or `null` if unset.
  final FontStyle? fontStyle;

  /// Bold / normal font weight, or `null` if unset.
  final FontWeight? fontWeight;

  /// Underline / strikethrough decoration, or `null` if unset.
  final TextDecoration? decoration;

  /// Converts this rule to a Flutter [TextStyle].
  TextStyle toTextStyle() {
    return TextStyle(
      color: foreground,
      backgroundColor: background,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      decoration: decoration,
    );
  }

  /// Parses a single `tokenColors` entry. Returns `null` if the entry has no
  /// usable scope.
  static TokenColorRule? _fromJson(Map<String, Object?> json) {
    // Normalise scope to a list of strings.
    final rawScope = json['scope'];
    final List<String> scopes;
    if (rawScope == null) {
      scopes = const [];
    } else if (rawScope is String) {
      // A single scope may itself be a comma-separated list.
      scopes = rawScope
          .split(',') //
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawScope is List) {
      scopes = rawScope
          .whereType<String>() //
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      scopes = const [];
    }

    if (scopes.isEmpty) return null;

    final settings = (json['settings'] as Map<String, Object?>?) ?? {};
    final fg = SyntaxTheme._parseColor(settings['foreground'] as String?);
    final bg = SyntaxTheme._parseColor(settings['background'] as String?);

    // Parse fontStyle string which may contain 'bold', 'italic', 'underline',
    // 'strikethrough' space-separated.
    FontStyle? fontStyle;
    FontWeight? fontWeight;
    TextDecoration? decoration;

    final fontStyleStr = settings['fontStyle'] as String?;
    if (fontStyleStr != null) {
      final parts = fontStyleStr.split(RegExp(r'\s+')).toSet();
      if (parts.contains('italic')) fontStyle = FontStyle.italic;
      if (parts.contains('bold')) fontWeight = FontWeight.bold;

      final decorations = <TextDecoration>[];
      if (parts.contains('underline')) //
        decorations.add(TextDecoration.underline);
      if (parts.contains('strikethrough')) {
        decorations.add(TextDecoration.lineThrough);
      }
      if (decorations.isNotEmpty) {
        decoration = TextDecoration.combine(decorations);
      }
    }

    return TokenColorRule._(
      scopes: scopes,
      foreground: fg,
      background: bg,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      decoration: decoration,
    );
  }
}
