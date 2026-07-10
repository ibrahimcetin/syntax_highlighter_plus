import 'onig_reg_exp.dart';

class RegexUtils {
  /// Expands backreferences in a pattern string (e.g., \1, \2) using the matched groups.
  static String expandBackreferences(String pattern, OnigMatch match, String source) {
    return pattern.replaceAllMapped(RegExp(r'(?<!\\)\\(\d+)'), (bm) {
      final idx = int.parse(bm.group(1)!);
      if (idx <= match.groupCount) {
        final gStart = match.groupStart(idx);
        final gEnd = match.groupEnd(idx);
        if (gStart >= 0 && gEnd >= 0) {
          return escapeRegex(source.substring(gStart, gEnd));
        }
      }
      return bm.group(0)!;
    });
  }

  /// Escapes special regex characters in a string to be used as a literal in a regex.
  static String escapeRegex(String text) {
    return text.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m.group(0)}');
  }
}
