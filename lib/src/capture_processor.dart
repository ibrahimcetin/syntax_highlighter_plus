import 'package:flutter/widgets.dart';

import 'onig_reg_exp.dart';
import 'span_builder.dart';
import 'syntax_theme.dart';

class _Capture {
  final int start;
  final int end;
  final TextStyle style;

  _Capture(this.start, this.end, this.style);
}

class CaptureProcessor {
  static void processCaptures({
    required OnigMatch match,
    required Map<String, dynamic> captures,
    required TextStyle baseStyle,
    required SyntaxTheme? theme,
    required SpanBuilder builder,
  }) {
    final caps = <_Capture>[];
    for (int i = 0; i <= match.groupCount; i++) {
      if (captures.containsKey(i.toString())) {
        final c = captures[i.toString()];
        if (c is Map) {
          final name = c['name'] as String?;
          final start = match.groupStart(i);
          final end = match.groupEnd(i);
          if (name != null && start >= 0 && end >= 0 && start != end) {
            caps.add(_Capture(start, end, theme?.resolveStyle(name) ?? const TextStyle()));
          }
        }
      }
    }

    if (caps.isEmpty) {
      builder.addText(match.start, match.end, baseStyle);
      return;
    }

    caps.sort((a, b) {
      if (a.start != b.start) return a.start.compareTo(b.start);
      return b.end.compareTo(a.end);
    });

    int charPos = match.start;
    while (charPos < match.end) {
      var style = baseStyle;
      int nextChange = match.end;

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

      builder.addText(charPos, nextChange, style);
      charPos = nextChange;
    }
  }
}
