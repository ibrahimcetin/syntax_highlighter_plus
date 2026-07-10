# syntax_highlighter_plus

A robust syntax highlighting Flutter package powered by TextMate grammars and themes.

## Features

- Uses standard TextMate grammars (`.json`) for accurate syntax highlighting.
- Supports TextMate themes for customizable styling.
- Easy to integrate with your Flutter applications.

## Usage

Here is a basic example of how to use the `SyntaxHighlighterPlus` class to highlight Dart code:

```dart
import 'package:flutter/material.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

class HighlightedText extends StatelessWidget {
  const HighlightedText({super.key});

  @override
  Widget build(BuildContext context) {
    final syntaxHighlighter = SyntaxHighlighterPlus(theme: 'github-dark');
    final highlightFuture = syntaxHighlighter.highlight('dart', 'print("Hello, World!");');

    return FutureBuilder<TextSpan>(
      future: highlightFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final span = snapshot.data ?? const TextSpan(text: 'print("Hello, World!");');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText.rich(
            span,
            style: const TextStyle(fontFamily: 'monospace', height: 1.6),
          ),
        );
      },
    );
  }
}
```
