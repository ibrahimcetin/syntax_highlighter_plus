import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('highlights dart source end to end', (tester) async {
    const highlighter = SyntaxHighlighterPlus(theme: 'github-dark');
    final span = await highlighter.highlight(
      'dart',
      'void main() {\n  print("hello");\n}\n',
    );

    // The span must reproduce the source text exactly.
    expect(span.toPlainText(), 'void main() {\n  print("hello");\n}\n');

    // And carry more than one style (i.e. real highlighting happened).
    final styles = <TextStyle?>{};
    span.visitChildren((child) {
      styles.add(child.style);
      return true;
    });
    expect(styles.length, greaterThan(1));
  });

  testWidgets('resolves aliases and supports both themes', (tester) async {
    for (final theme in SyntaxHighlighterPlus.supportedThemes) {
      final highlighter = SyntaxHighlighterPlus(theme: theme);
      final span = await highlighter.highlight('py', 'x = 1\n');
      expect(span.toPlainText(), 'x = 1\n');
    }
  });
}
