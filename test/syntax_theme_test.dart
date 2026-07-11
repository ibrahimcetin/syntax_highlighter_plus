import 'dart:ui' show Brightness, Color;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

SyntaxTheme _theme() => SyntaxTheme.fromJson('test-theme', {
      'type': 'dark',
      'colors': {
        'editor.foreground': '#e1e4e8',
        'editor.background': '#24292e',
      },
      'tokenColors': [
        {
          'scope': ['comment', 'punctuation.definition.comment'],
          'settings': {'foreground': '#6a737d'},
        },
        {
          'scope': 'keyword',
          'settings': {'foreground': '#f97583'},
        },
        {
          'scope': 'string',
          'settings': {'foreground': '#9ecbff'},
        },
        {
          // Descendant selector: strings inside meta.embedded stay default.
          'scope': 'meta.embedded string',
          'settings': {'foreground': '#ffffff'},
        },
        {
          // More specific prefix must beat the shorter one.
          'scope': 'keyword.operator',
          'settings': {'foreground': '#79b8ff'},
        },
        {
          'scope': 'markup.italic',
          'settings': {'fontStyle': 'italic'},
        },
        {
          'scope': 'markup.bold',
          'settings': {'fontStyle': 'bold underline'},
        },
      ],
    });

void main() {
  group('SyntaxTheme parsing', () {
    test('reads editor colors and brightness', () {
      final theme = _theme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.foreground, const Color(0xFFE1E4E8));
      expect(theme.background, const Color(0xFF24292E));
    });
  });

  group('scope selector matching', () {
    test('prefix match on dotted scopes', () {
      final theme = _theme();
      final style = theme.styleFor(['source.dart', 'keyword.control.dart']);
      expect(style.color, const Color(0xFFF97583));
    });

    test('does not match partial segments', () {
      final theme = _theme();
      // "keywordish" must not match the "keyword" selector.
      final style = theme.styleFor(['source.dart', 'keywordish.thing']);
      expect(style.color, isNull);
    });

    test('longer prefix wins over shorter', () {
      final theme = _theme();
      final style = theme.styleFor(['source.dart', 'keyword.operator.assignment']);
      expect(style.color, const Color(0xFF79B8FF));
    });

    test('deeper scope wins over shallower', () {
      final theme = _theme();
      // Both "comment" (depth 1) and "keyword" (depth 2) match somewhere;
      // the deeper one must win.
      final style = theme.styleFor(['source.dart', 'comment.block', 'keyword.control']);
      expect(style.color, const Color(0xFFF97583));
    });

    test('descendant selector requires ancestor', () {
      final theme = _theme();
      final embedded = theme.styleFor(
        ['text.html', 'meta.embedded.block', 'string.quoted'],
      );
      expect(embedded.color, const Color(0xFFFFFFFF));

      final plain = theme.styleFor(['source.js', 'string.quoted']);
      expect(plain.color, const Color(0xFF9ECBFF));
    });

    test('font styles map to TextStyle', () {
      final theme = _theme();
      final italic = theme.styleFor(['text.md', 'markup.italic.md']);
      expect(italic.fontStyle, FontStyle.italic);

      final bold = theme.styleFor(['text.md', 'markup.bold.md']);
      expect(bold.fontWeight, FontWeight.bold);
      expect(bold.decoration, TextDecoration.underline);
    });

    test('color and fontStyle resolve independently', () {
      final theme = _theme();
      // markup.italic sets only fontStyle; keyword sets only color; a stack
      // hitting both should merge them.
      final style = theme.styleFor(['text.md', 'markup.italic.md', 'keyword.control']);
      expect(style.color, const Color(0xFFF97583));
      expect(style.fontStyle, FontStyle.italic);
    });
  });
}
