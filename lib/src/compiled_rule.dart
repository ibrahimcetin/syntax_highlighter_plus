import 'onig_reg_exp.dart';

abstract class CompiledRule {}

class MatchRule extends CompiledRule {
  final OnigRegExp regex;
  final String? scopeName;
  final Map<String, dynamic>? captures;

  MatchRule({
    required this.regex,
    this.scopeName,
    this.captures,
  });
}

class BeginEndRule extends CompiledRule {
  final OnigRegExp beginRegex;
  final String? endPattern;
  final String? nameScope;
  final String? contentScope;
  final Map<String, dynamic>? beginCaptures;
  final Map<String, dynamic>? endCaptures;
  final Map<String, dynamic>? captures;
  final List<CompiledRule> children;

  BeginEndRule({
    required this.beginRegex,
    this.endPattern,
    this.nameScope,
    this.contentScope,
    this.beginCaptures,
    this.endCaptures,
    this.captures,
    required this.children,
  });
}

class IncludeRule extends CompiledRule {
  final String reference;

  IncludeRule(this.reference);
}

class ContainerRule extends CompiledRule {
  final List<CompiledRule> children;

  ContainerRule(this.children);
}
