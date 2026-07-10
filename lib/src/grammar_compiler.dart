import 'compiled_rule.dart';
import 'onig_reg_exp.dart';

class GrammarCompiler {
  final Map<String, dynamic> rawGrammar;
  late final Map<String, CompiledRule> repository;
  late final CompiledRule rootRule;

  GrammarCompiler(this.rawGrammar) {
    repository = _compileRepository(rawGrammar['repository'] as Map<String, dynamic>?);
    rootRule = _compileContainer(rawGrammar);
  }

  Map<String, CompiledRule> _compileRepository(Map<String, dynamic>? repo) {
    if (repo == null) return {};
    final result = <String, CompiledRule>{};
    for (final entry in repo.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _compileRuleMap(entry.value as Map<String, dynamic>);
      }
    }
    return result;
  }

  CompiledRule _compileRuleMap(Map<String, dynamic> rule) {
    if (rule.containsKey('include')) {
      final include = rule['include'] as String;
      return IncludeRule(include);
    } else if (rule.containsKey('match')) {
      return MatchRule(
        regex: OnigRegExp(rule['match'] as String),
        scopeName: rule['name'] as String?,
        captures: rule['captures'] as Map<String, dynamic>?,
      );
    } else if (rule.containsKey('begin')) {
      String? endRaw = rule['end'] as String?;
      endRaw ??= rule['while'] as String?;

      return BeginEndRule(
        beginRegex: OnigRegExp(rule['begin'] as String),
        endPattern: endRaw,
        nameScope: rule['name'] as String?,
        contentScope: rule['contentName'] as String?,
        beginCaptures: rule['beginCaptures'] as Map<String, dynamic>? ?? rule['captures'] as Map<String, dynamic>?,
        endCaptures: rule['endCaptures'] as Map<String, dynamic>? ?? rule['captures'] as Map<String, dynamic>?,
        captures: rule['captures'] as Map<String, dynamic>?,
        children: _compilePatterns(rule['patterns'] as List<dynamic>?),
      );
    } else if (rule.containsKey('patterns')) {
      return _compileContainer(rule);
    }

    return ContainerRule([]);
  }

  ContainerRule _compileContainer(Map<String, dynamic> rule) {
    return ContainerRule(_compilePatterns(rule['patterns'] as List<dynamic>?));
  }

  List<CompiledRule> _compilePatterns(List<dynamic>? patterns) {
    if (patterns == null) return [];
    final result = <CompiledRule>[];
    for (final p in patterns) {
      if (p is Map) {
        // cast to Map<String, dynamic>
        final map = p.map((key, value) => MapEntry(key.toString(), value));
        result.add(_compileRuleMap(map));
      }
    }
    return result;
  }
}
