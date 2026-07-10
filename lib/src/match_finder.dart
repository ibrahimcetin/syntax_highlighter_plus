import 'compiled_rule.dart';
import 'onig_reg_exp.dart';

class MatchResult {
  final OnigMatch match;
  final CompiledRule? rule;
  final bool isEnd;

  MatchResult(this.match, this.rule, this.isEnd);
}

class MatchFinder {
  static MatchResult? findNextMatch(
    List<CompiledRule> rules,
    OnigRegExp? endRegex,
    int startPos,
    String text,
    Map<String, CompiledRule> repository,
    CompiledRule rootRule,
  ) {
    MatchResult? bestMatch;

    if (endRegex != null) {
      final match = endRegex.search(text, startPos);
      if (match != null) {
        bestMatch = MatchResult(match, null, true);
      }
    }

    for (final rule in rules) {
      final resolved = _resolveRule(rule, repository, rootRule);
      if (resolved == null) continue;

      if (resolved is MatchRule) {
        final match = resolved.regex.search(text, startPos);
        if (match != null) {
          if (bestMatch == null || match.start < bestMatch.match.start) {
            bestMatch = MatchResult(match, resolved, false);
          }
        }
      } else if (resolved is BeginEndRule) {
        final match = resolved.beginRegex.search(text, startPos);
        if (match != null) {
          if (bestMatch == null || match.start < bestMatch.match.start) {
            bestMatch = MatchResult(match, resolved, false);
          }
        }
      } else if (resolved is ContainerRule) {
        final innerMatch = findNextMatch(resolved.children, null, startPos, text, repository, rootRule);
        if (innerMatch != null) {
          if (bestMatch == null || innerMatch.match.start < bestMatch.match.start) {
            bestMatch = innerMatch;
          }
        }
      }
    }
    return bestMatch;
  }

  static CompiledRule? _resolveRule(CompiledRule rule, Map<String, CompiledRule> repository, CompiledRule rootRule) {
    CompiledRule? current = rule;
    final visited = <String>{};

    while (current is IncludeRule) {
      final include = current.reference;
      if (visited.contains(include)) return null; // Prevent infinite loop on circular includes
      visited.add(include);

      if (include.startsWith('#')) {
        current = repository[include.substring(1)];
      } else if (include == r'$self' || include == r'$base') {
        current = rootRule;
      } else {
        return null;
      }
    }
    return current;
  }
}
