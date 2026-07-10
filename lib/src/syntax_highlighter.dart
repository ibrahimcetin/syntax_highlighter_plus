import 'package:flutter/widgets.dart';

import 'onig_reg_exp.dart';
import 'syntax_theme.dart';

class _Capture {
  final int start;
  final int end;
  final TextStyle style;
  _Capture(this.start, this.end, this.style);
}

class _RuleContext {
  final Map<String, dynamic> rule;
  final String? nameScope;
  final String? contentScope;
  final OnigRegExp? endRegex;
  final Map<String, dynamic>? endCaptures;
  final Map<String, dynamic>? captures;

  _RuleContext({
    required this.rule,
    this.nameScope,
    this.contentScope,
    this.endRegex,
    this.endCaptures,
    this.captures,
  });
}

class _MatchResult {
  final OnigMatch match;
  final Map<String, dynamic> rule;
  final bool isEnd;
  _MatchResult(this.match, this.rule, this.isEnd);
}

class SyntaxHighlighter {
  SyntaxHighlighter({required this.grammar, required this.source});

  final Map<String, dynamic> grammar;
  final String source;

  static final Map<String, OnigRegExp> _regexCache = {};

  static OnigRegExp _getRegex(String pattern) {
    return _regexCache.putIfAbsent(pattern, () => OnigRegExp(pattern));
  }

  /// Highlights [source] and returns the result as a [TextSpan].
  TextSpan highlight({SyntaxTheme? theme}) {
    final spans = <TextSpan>[];
    int currentPos = 0;

    final stack = <_RuleContext>[
      _RuleContext(
        rule: grammar,
        contentScope: grammar['scopeName'] as String?,
      )
    ];

    while (currentPos < source.length) {
      final top = stack.last;
      final patterns = top.rule['patterns'] as List<dynamic>? ?? [];

      final result = _findNextMatch(patterns, top.endRegex, currentPos, source);

      if (result != null) {
        final m = result.match;

        if (m.start > currentPos) {
          spans.addAll(_processText(source.substring(currentPos, m.start), _getCurrentStyle(stack, theme)));
        }

        if (result.isEnd) {
          final eCaptures = top.endCaptures ?? top.captures;
          if (eCaptures != null) {
            spans.addAll(_processCaptures(m, eCaptures, _getCurrentStyle(stack, theme), theme));
          } else {
            spans.addAll(_processText(source.substring(m.start, m.end), _getCurrentStyle(stack, theme)));
          }

          stack.removeLast();
          currentPos = m.end;
        } else {
          final rule = result.rule;
          final scopeName = rule['name'] as String?;
          final style = _getCurrentStyle(stack, theme).merge(theme?.resolveStyle(scopeName ?? '') ?? const TextStyle());

          if (rule.containsKey('match')) {
            final captures = rule['captures'] as Map<String, dynamic>?;
            if (captures != null) {
              spans.addAll(_processCaptures(m, captures, style, theme));
            } else {
              spans.addAll(_processText(source.substring(m.start, m.end), style));
            }
            currentPos = m.end;
            if (currentPos == m.start) {
              if (currentPos < source.length) {
                spans.addAll(_processText(source.substring(currentPos, currentPos + 1), _getCurrentStyle(stack, theme)));
                currentPos++;
              } else {
                break;
              }
            }
          } else if (rule.containsKey('begin')) {
            final bCaptures = rule['beginCaptures'] as Map<String, dynamic>? ?? rule['captures'] as Map<String, dynamic>?;
            if (bCaptures != null) {
              spans.addAll(_processCaptures(m, bCaptures, style, theme));
            } else {
              spans.addAll(_processText(source.substring(m.start, m.end), style));
            }

            String? endRaw = rule['end'] as String?;
            endRaw ??= rule['while'] as String?;

            OnigRegExp? endRegex;
            if (endRaw != null) {
              endRaw = endRaw.replaceAllMapped(RegExp(r'(?<!\\)\\(\d+)'), (bm) {
                final idx = int.parse(bm.group(1)!);
                if (idx <= m.groupCount) {
                  final gStart = m.groupStart(idx);
                  final gEnd = m.groupEnd(idx);
                  if (gStart >= 0 && gEnd >= 0) {
                    return source.substring(gStart, gEnd);
                  }
                }
                return bm.group(0)!;
              });
              endRegex = _getRegex(endRaw);
            }

            stack.add(_RuleContext(
              rule: rule,
              nameScope: scopeName,
              contentScope: rule['contentName'] as String?,
              endRegex: endRegex,
              endCaptures: rule['endCaptures'] as Map<String, dynamic>?,
              captures: rule['captures'] as Map<String, dynamic>?,
            ));

            currentPos = m.end;
          }
        }
      } else {
        spans.addAll(_processText(source.substring(currentPos), _getCurrentStyle(stack, theme)));
        break;
      }
    }

    return TextSpan(children: spans);
  }

  Map<String, dynamic>? _resolveRule(Map<String, dynamic> rule) {
    if (rule.containsKey('include')) {
      final include = rule['include'] as String;
      if (include.startsWith('#')) {
        final repo = grammar['repository'] as Map<String, dynamic>?;
        if (repo != null) {
          final target = repo[include.substring(1)];
          if (target is Map) return target as Map<String, dynamic>;
        }
      } else if (include == r'$self' || include == r'$base') {
        return grammar;
      }
      return null;
    }
    return rule;
  }

  _MatchResult? _findNextMatch(List<dynamic> patterns, OnigRegExp? endRegex, int startPos, String text) {
    _MatchResult? bestMatch;

    if (endRegex != null) {
      final match = endRegex.search(text, startPos);
      if (match != null) {
        bestMatch = _MatchResult(match, {}, true);
      }
    }

    for (final p in patterns) {
      if (p is! Map) continue;
      final rule = _resolveRule(p as Map<String, dynamic>);
      if (rule == null) continue;

      if (rule.containsKey('match')) {
        final r = _getRegex(rule['match'] as String);
        final match = r.search(text, startPos);
        if (match != null) {
          if (bestMatch == null || match.start < bestMatch.match.start) {
            bestMatch = _MatchResult(match, rule, false);
          }
        }
      } else if (rule.containsKey('begin')) {
        final r = _getRegex(rule['begin'] as String);
        final match = r.search(text, startPos);
        if (match != null) {
          if (bestMatch == null || match.start < bestMatch.match.start) {
            bestMatch = _MatchResult(match, rule, false);
          }
        }
      } else if (rule.containsKey('patterns')) {
        final innerMatch = _findNextMatch(rule['patterns'] as List<dynamic>, null, startPos, text);
        if (innerMatch != null) {
          if (bestMatch == null || innerMatch.match.start < bestMatch.match.start) {
            bestMatch = innerMatch;
          }
        }
      }
    }
    return bestMatch;
  }

  TextStyle _getCurrentStyle(List<_RuleContext> stack, SyntaxTheme? theme) {
    var style = const TextStyle();
    if (theme == null) return style;
    for (final ctx in stack) {
      if (ctx.nameScope != null) style = style.merge(theme.resolveStyle(ctx.nameScope!));
      if (ctx.contentScope != null) style = style.merge(theme.resolveStyle(ctx.contentScope!));
    }
    return style;
  }

  List<TextSpan> _processCaptures(OnigMatch m, Map<String, dynamic> captures, TextStyle baseStyle, SyntaxTheme? theme) {
    final caps = <_Capture>[];
    for (int i = 0; i <= m.groupCount; i++) {
      if (captures.containsKey(i.toString())) {
        final c = captures[i.toString()];
        if (c is Map) {
          final name = c['name'] as String?;
          final start = m.groupStart(i);
          final end = m.groupEnd(i);
          if (name != null && start >= 0 && end >= 0 && start != end) {
            caps.add(_Capture(start, end, theme?.resolveStyle(name) ?? const TextStyle()));
          }
        }
      }
    }

    if (caps.isEmpty) {
      return _processText(source.substring(m.start, m.end), baseStyle);
    }

    caps.sort((a, b) {
      if (a.start != b.start) return a.start.compareTo(b.start);
      return b.end.compareTo(a.end);
    });

    final spans = <TextSpan>[];
    int charPos = m.start;
    while (charPos < m.end) {
      var style = baseStyle;
      int nextChange = m.end;

      for (final c in caps) {
        if (charPos >= c.start && charPos < c.end) {
          style = style.merge(c.style);
        }
        if (c.start > charPos && c.start < nextChange) {
          nextChange = c.start;
        }
        if (c.end > charPos && c.end < nextChange) {
          nextChange = c.end;
        }
      }

      spans.addAll(_processText(source.substring(charPos, nextChange), style));
      charPos = nextChange;
    }

    return spans;
  }

  List<TextSpan> _processText(String text, TextStyle style) {
    if (text.isEmpty) return const [];
    return [TextSpan(text: text, style: style)];
  }
}
