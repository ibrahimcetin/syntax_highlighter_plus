import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlighter_plus/src/span_builder.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

final _theme = SyntaxTheme.fromJson('test-theme', {
  'type': 'dark',
  'colors': {'editor.foreground': '#ffffff', 'editor.background': '#000000'},
  'tokenColors': [
    {
      'scope': 'keyword',
      'settings': {'foreground': '#ff0000'},
    },
    {
      'scope': 'string',
      'settings': {'foreground': '#00ff00'},
    },
  ],
});

void main() {
  test('span text reproduces the source exactly', () {
    const source = 'if (x) {\n  y = "z";\n}\n';
    final tokens = [
      Token(start: 0, end: 2, scopes: const ['source', 'keyword.control']),
      Token(start: 2, end: 8, scopes: const ['source']),
      // gap: newline (8..9) has no token, like real tokenizer output
      Token(start: 9, end: 15, scopes: const ['source']),
      Token(start: 15, end: 18, scopes: const ['source', 'string.quoted']),
      Token(start: 18, end: 19, scopes: const ['source']),
      Token(start: 20, end: 21, scopes: const ['source']),
    ];
    final span = buildTextSpan(source: source, tokens: tokens, theme: _theme);
    expect(span.toPlainText(), source);
  });

  test('styles are applied and adjacent identical runs merge', () {
    const source = 'ab cd';
    final tokens = [
      Token(start: 0, end: 2, scopes: const ['source', 'keyword']),
      Token(start: 2, end: 3, scopes: const ['source']),
      Token(start: 3, end: 5, scopes: const ['source']),
    ];
    final span = buildTextSpan(source: source, tokens: tokens, theme: _theme);

    final children = span.children!.cast<TextSpan>();
    // " " and "cd" resolve to the same (default) style -> merged into one.
    expect(children.length, 2);
    expect(children[0].text, 'ab');
    expect(children[0].style?.color, const Color(0xFFFF0000));
    expect(children[1].text, ' cd');
    expect(children[1].style, isNull);
  });

  test('root style carries theme foreground over base style', () {
    final span = buildTextSpan(
      source: 'x',
      tokens: [Token(start: 0, end: 1, scopes: const ['source'])],
      theme: _theme,
      baseStyle: const TextStyle(fontFamily: 'monospace'),
    );
    expect(span.style?.color, const Color(0xFFFFFFFF));
    expect(span.style?.fontFamily, 'monospace');
  });

  test('out-of-range tokens are clamped', () {
    final span = buildTextSpan(
      source: 'ab',
      tokens: [Token(start: 0, end: 99, scopes: const ['source', 'keyword'])],
      theme: _theme,
    );
    expect(span.toPlainText(), 'ab');
  });
}
