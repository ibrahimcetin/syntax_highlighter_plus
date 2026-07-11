# Changelog

## 0.1.0

* Replaced the C FFI Oniguruma binding with a Rust TextMate tokenization
  engine (the `onig` crate via `flutter_rust_bridge`). Tokenization now runs
  asynchronously off the UI thread.
* TextMate grammars are embedded into the native library at build time;
  embedded languages (e.g. code blocks inside markdown, JS inside HTML) are
  resolved across grammars.
* Added VS Code theme parsing with TextMate scope-selector matching
  (`SyntaxTheme`), including font styles (italic/bold/underline/strikethrough).
* `highlight()` returns a compact `TextSpan` tree; adjacent runs with equal
  styles are merged. An optional `style` parameter supplies the base
  `TextStyle`.
* Token offsets are UTF-16 code units, correct for emoji/CJK sources.

## 0.0.2

* Integrated Oniguruma as the underlying regular expression engine for improved parsing and compatibility with TextMate grammars.

## 0.0.1

* Initial release.
