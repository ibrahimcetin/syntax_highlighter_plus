import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Syntax Highlighter simple test', (tester) async {
    final highlighter = SyntaxHighlighterPlus(theme: 'github-dark');
    final textSpan = await highlighter.highlight('dart', 'void main() {}');
    
    expect(textSpan.children, isNotEmpty);
    print(textSpan.toStringDeep());
  });
}
