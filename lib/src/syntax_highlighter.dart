import 'package:flutter/widgets.dart';

import 'capture_processor.dart';
import 'compiled_rule.dart';
import 'grammar_compiler.dart';
import 'match_finder.dart';
import 'onig_reg_exp.dart';
import 'regex_utils.dart';
import 'rule_context.dart';
import 'span_builder.dart';
import 'syntax_theme.dart';

class SyntaxHighlighter {
  SyntaxHighlighter({required this.grammar, required this.source}) {
    _compiler = _getCompiler(grammar);
  }

  final Map<String, dynamic> grammar;
  final String source;
  late final GrammarCompiler _compiler;

  static final Expando<GrammarCompiler> _compilerCache = Expando();

  static GrammarCompiler _getCompiler(Map<String, dynamic> grammar) {
    var compiler = _compilerCache[grammar];
    if (compiler == null) {
      compiler = GrammarCompiler(grammar);
      _compilerCache[grammar] = compiler;
    }
    return compiler;
  }

  /// Highlights [source] and returns the result as a [TextSpan].
  TextSpan highlight({SyntaxTheme? theme}) {
    final builder = SpanBuilder(source);
    int currentPos = 0;

    final rootStyle = theme?.resolveStyle(_compiler.rawGrammar['scopeName'] as String? ?? '') ?? const TextStyle();

    final stack = <RuleContext>[
      RuleContext(
        rule: _compiler.rootRule,
        mergedStyle: rootStyle,
        contentScope: _compiler.rawGrammar['scopeName'] as String?,
      )
    ];

    while (currentPos < source.length) {
      final top = stack.last;
      
      final patterns = <CompiledRule>[];
      if (top.rule is BeginEndRule) {
        patterns.addAll((top.rule as BeginEndRule).children);
      } else if (top.rule is ContainerRule) {
        patterns.addAll((top.rule as ContainerRule).children);
      }

      final result = MatchFinder.findNextMatch(
        patterns,
        top.endRegex,
        currentPos,
        source,
        _compiler.repository,
        _compiler.rootRule,
      );

      if (result != null) {
        final m = result.match;

        if (m.start > currentPos) {
          builder.addText(currentPos, m.start, top.mergedStyle);
        }

        if (result.isEnd) {
          final eCaptures = top.endCaptures ?? top.captures;
          if (eCaptures != null) {
            CaptureProcessor.processCaptures(
              match: m,
              captures: eCaptures,
              baseStyle: top.mergedStyle,
              theme: theme,
              builder: builder,
            );
          } else {
            builder.addText(m.start, m.end, top.mergedStyle);
          }

          stack.removeLast();
          currentPos = m.end;
        } else {
          final rule = result.rule;
          if (rule == null) continue;

          String? scopeName;
          if (rule is MatchRule) scopeName = rule.scopeName;
          if (rule is BeginEndRule) scopeName = rule.nameScope;

          final style = top.mergedStyle.merge(theme?.resolveStyle(scopeName ?? '') ?? const TextStyle());

          if (rule is MatchRule) {
            final captures = rule.captures;
            if (captures != null) {
              CaptureProcessor.processCaptures(
                match: m,
                captures: captures,
                baseStyle: style,
                theme: theme,
                builder: builder,
              );
            } else {
              builder.addText(m.start, m.end, style);
            }
            currentPos = m.end;
            if (currentPos == m.start) {
              // Prevent infinite loop on zero-width match
              if (currentPos < source.length) {
                builder.addText(currentPos, currentPos + 1, top.mergedStyle);
                currentPos++;
              } else {
                break;
              }
            }
          } else if (rule is BeginEndRule) {
            final bCaptures = rule.beginCaptures ?? rule.captures;
            if (bCaptures != null) {
              CaptureProcessor.processCaptures(
                match: m,
                captures: bCaptures,
                baseStyle: style,
                theme: theme,
                builder: builder,
              );
            } else {
              builder.addText(m.start, m.end, style);
            }

            OnigRegExp? endRegex;
            if (rule.endPattern != null) {
              final expandedEnd = RegexUtils.expandBackreferences(rule.endPattern!, m, source);
              endRegex = OnigRegExp(expandedEnd);
            }

            stack.add(RuleContext(
              rule: rule,
              mergedStyle: style.merge(theme?.resolveStyle(rule.contentScope ?? '') ?? const TextStyle()),
              nameScope: scopeName,
              contentScope: rule.contentScope,
              endRegex: endRegex,
              endCaptures: rule.endCaptures,
              captures: rule.captures,
            ));

            currentPos = m.end;
          }
        }
      } else {
        builder.addText(currentPos, source.length, top.mergedStyle);
        break;
      }
    }

    return builder.build();
  }
}
