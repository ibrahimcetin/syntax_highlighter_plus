# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter FFI plugin for syntax highlighting: TextMate grammars are tokenized by a Rust engine (Oniguruma via the `onig` crate) exposed through `flutter_rust_bridge` (FRB); theming and `TextSpan` building happen in Dart. Built for streaming markdown/chat use cases, so repeated highlighting must be cheap (everything is cached lazily per process).

## Commands

```sh
# Dart unit tests (pure Dart, no Rust build needed)
flutter test
flutter test test/span_builder_test.dart          # single file

# Integration tests (exercise the real Rust tokenizer; need a device)
cd example && flutter test integration_test -d macos
cd example && flutter test integration_test/highlight_test.dart -d macos

# Lint / format
flutter analyze
dart format .
dart run import_sorter:main                        # import ordering (config in pubspec: comments off)

# Rust engine alone (fast iteration on the tokenizer)
cd rust && cargo check
cd rust && cargo test

# Regenerate FRB bindings after changing rust/src/api/
flutter_rust_bridge_codegen generate                # config: flutter_rust_bridge.yaml

# Example app
cd example && flutter run -d macos
```

FRB is pinned to exactly 2.12.0 in both `pubspec.yaml` and `rust/Cargo.toml`; the codegen CLI version must match. `lib/src/rust/` and `rust/src/frb_generated.rs` are generated — never hand-edit, regenerate instead.

## Architecture

The highlight pipeline (`lib/syntax_highlighter_plus.dart`):

1. `GrammarRegistry.resolve` (Dart, `lib/src/grammar_registry.dart`) maps a fence tag/alias (`py`, `c++`) to a canonical grammar id. Throws `ArgumentError` for unknown tags — this is API contract, callers rely on it to fall back to plain text.
2. `rust.tokenize(language, source)` runs on an FRB worker thread. Grammar JSON is parsed and regexes compiled lazily, cached for the process lifetime (`rust/src/textmate/`: `raw.rs` JSON model → `grammar.rs` compiled rules → `tokenizer.rs` begin/end/while stack machine, `regex.rs` onig wrapper).
3. Tokens come back as `(start, end, scopes)` with **UTF-16 offsets**, directly usable as Dart string indices. UTF-16 correctness is a known bug class — integration tests include emoji/non-ASCII samples for this.
4. `ThemeRegistry` (Dart) parses VS Code theme JSON from `assets/themes/`; `span_builder.dart` matches each token's scope stack against theme selectors and merges adjacent same-style runs into a compact `TextSpan` tree.

### Asset split (important, easy to get wrong)

- **Grammars** (`assets/grammars/<id>.json.zst`, zstd-compressed) are embedded into the Rust binary at build time by `rust/build.rs`, which decompresses each one to extract its `scopeName` (needed to resolve cross-grammar includes like `source.js` inside the html grammar) and embeds only the compressed bytes. At runtime a grammar is decompressed (via `ruzstd`) and parsed on first use, then cached. They are deliberately **not** Flutter assets.
- **Themes** (`assets/themes/`) **are** Flutter assets, parsed in Dart.

### Adding a grammar or theme

The language/theme lists are duplicated between assets and Dart registries and must stay in sync:

- Grammar: compress the TextMate JSON with `zstd -19 <file> -o assets/grammars/<id>.json.zst`, add the id to `GrammarRegistry._languages` (plus any aliases in `_aliases`), rebuild Rust. `example/integration_test/grammars_test.dart` exercises every registered grammar and will catch mismatches.
- Theme: drop the JSON into `assets/themes/`, add the id to `ThemeRegistry._themes`.

### Native build

`cargokit/` builds the Rust crate for each platform; the plugin is `ffiPlugin: true` for all five desktop/mobile platforms (no platform channel code). `RustLib.init()` is lazy and tolerates the host app having initialized FRB itself.
