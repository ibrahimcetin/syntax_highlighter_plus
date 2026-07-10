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
      title: 'Syntax Highlighter Plus — Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: MediaQuery.platformBrightnessOf(context),
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
          seedColor: Colors.cyan,
        ),
        useMaterial3: true,
      ),
      home: const CodeViewerPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sample Dart source to display
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CodeViewerPage extends StatefulWidget {
  const CodeViewerPage({super.key});

  @override
  State<CodeViewerPage> createState() => _CodeViewerPageState();
}

class _CodeViewerPageState extends State<CodeViewerPage> {
  final _highlighter = SyntaxHighlighterPlus();
  late Future<TextSpan> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize once — we need context here for Theme.of(context) inside highlight().
    if (!_initialized) {
      _initialized = true;
      _future = _highlighter.highlight(context, _dartSample, 'dart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('syntax_highlighter_plus'),
        centerTitle: false,
      ),
      body: FutureBuilder<TextSpan>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // While loading: show plain text. When done: show highlighted text.
          final span = snapshot.data ?? const TextSpan(text: _dartSample);
          return _codeView(span);
        },
      ),
    );
  }

  Widget _codeView(TextSpan span) {
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
  }
}
