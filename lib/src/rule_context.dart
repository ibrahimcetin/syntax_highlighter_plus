import 'package:flutter/widgets.dart';

import 'compiled_rule.dart';
import 'onig_reg_exp.dart';

class RuleContext {
  final CompiledRule rule;
  final TextStyle mergedStyle;
  final String? nameScope;
  final String? contentScope;
  final OnigRegExp? endRegex;
  final Map<String, dynamic>? endCaptures;
  final Map<String, dynamic>? captures;

  RuleContext({
    required this.rule,
    required this.mergedStyle,
    this.nameScope,
    this.contentScope,
    this.endRegex,
    this.endCaptures,
    this.captures,
  });
}
