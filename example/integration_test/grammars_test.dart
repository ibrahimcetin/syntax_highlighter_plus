import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// The raw tokenizer and registry are implementation details; tests reach in
// to verify every grammar, not just the public happy path.
// ignore: implementation_imports
import 'package:syntax_highlighter_plus/src/grammar_registry.dart';
// ignore: implementation_imports
import 'package:syntax_highlighter_plus/src/rust/api/highlighter.dart' as rust;
// ignore: implementation_imports
import 'package:syntax_highlighter_plus/src/rust/frb_generated.dart';
import 'package:syntax_highlighter_plus/syntax_highlighter_plus.dart';

/// Exercises keywords, strings, numbers, comments, tags, and non-ASCII text
/// (to catch UTF-16 offset bugs).
const _sample = '''
# comment <tag attr="value">
def main(items):
    total = 0
    for item in items:
        total += item.price * 1.25
    return "done 🎉"

SELECT * FROM users WHERE id = 42; -- query
{ "key": [1, true, null] }
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => RustLib.init());

  testWidgets('every bundled grammar loads and tokenizes without errors',
      (tester) async {
    final failures = <String, Object>{};

    for (final language in rust.supportedLanguages()) {
      try {
        final tokens = await rust.tokenize(language: language, source: _sample);

        // Sanity-check the token stream: sorted, non-empty ranges, in bounds.
        var previousEnd = 0;
        for (final token in tokens) {
          if (token.start < previousEnd ||
              token.end <= token.start ||
              token.end > _sample.length ||
              token.scopes.isEmpty) {
            throw StateError(
              'bad token ${token.start}..${token.end} ${token.scopes}',
            );
          }
          previousEnd = token.end;
        }
      } catch (e) {
        failures[language] = e;
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'grammars failed:\n'
          '${failures.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
    );
  });

  testWidgets('every Dart-registry language tag resolves to a bundled grammar',
      (tester) async {
    final bundled = rust.supportedLanguages().toSet();
    for (final tag in SyntaxHighlighterPlus.supportedLanguages) {
      final canonicalId = GrammarRegistry.resolve(tag);
      expect(bundled, contains(canonicalId),
          reason: '"$tag" resolves to "$canonicalId", which is not bundled');
    }
  });

  testWidgets('full pipeline round-trips the source for every language tag',
      (tester) async {
    const highlighter = SyntaxHighlighterPlus(theme: 'github-dark');
    final failures = <String, Object>{};

    for (final language in SyntaxHighlighterPlus.supportedLanguages) {
      try {
        final span = await highlighter.highlight(language, _sample);
        final text = span.toPlainText();
        if (text != _sample) {
          failures[language] =
              'span text does not round-trip (${text.length} vs ${_sample.length} chars)';
        }
      } catch (e) {
        failures[language] = e;
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'highlighting failed:\n'
          '${failures.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
    );
  });

  testWidgets('empty and single-line sources are handled by every language',
      (tester) async {
    const highlighter = SyntaxHighlighterPlus(theme: 'github-light');

    for (final language in SyntaxHighlighterPlus.supportedLanguages) {
      final empty = await highlighter.highlight(language, '');
      expect(empty.toPlainText(), '', reason: 'empty source for $language');

      final single = await highlighter.highlight(language, 'x = 1');
      expect(single.toPlainText(), 'x = 1',
          reason: 'single line for $language');
    }
  });
}
