import 'package:flutter/widgets.dart';

class SpanBuilder {
  final List<TextSpan> _spans = [];
  final String source;

  SpanBuilder(this.source);

  void addText(int start, int end, TextStyle style) {
    if (start >= end || start >= source.length) return;
    _spans.add(TextSpan(text: source.substring(start, end), style: style));
  }

  void addPlain(String text, TextStyle style) {
    if (text.isEmpty) return;
    _spans.add(TextSpan(text: text, style: style));
  }

  TextSpan build() {
    return TextSpan(children: _spans);
  }
}
