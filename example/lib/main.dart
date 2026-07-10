import 'package:flutter/material.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syntax Highlighter Plus',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('syntax_highlighter_plus')),
        body: const HighlightedText(),
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText({super.key});

  @override
  Widget build(BuildContext context) {
    final syntaxHighlighter = SyntaxHighlighterPlus(theme: 'github-dark');
    final highlightFuture = syntaxHighlighter.highlight('dart', _dartSample);

    return FutureBuilder<TextSpan>(
      future: highlightFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Get the highlighted text span, falling back to non-highlighted text if not available.
        final span = snapshot.data ?? const TextSpan(text: _dartSample);

        // Display the highlighted text in a scrollable view.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText.rich(
              span,
              style: const TextStyle(fontFamily: 'monospace', height: 1.6),
            ),
          ),
        );
      },
    );
  }
}

const _dartSample = r'''
void main() {
  final numbers = [1, 2, 3, 4, 5];
  final doubled = numbers.map((n) => n * 2).toList();
  print(doubled); // [2, 4, 6, 8, 10]
}

/// Returns the nth Fibonacci number.
int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

class Counter {
  int _count = 0;

  void increment() => _count++;
  void reset() => _count = 0;

  int get value => _count;

  @override
  String toString() => 'Counter($_count)';
}
''';
