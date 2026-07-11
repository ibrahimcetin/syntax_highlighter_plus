//! Embeds the TextMate grammar JSON files from `../assets/grammars` into the
//! binary. For each grammar we extract its `scopeName` at build time so the
//! registry can resolve cross-grammar includes (e.g. `source.js` inside
//! `html.json`) without parsing every file up front.

use std::env;
use std::fs;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let grammars_dir = manifest_dir.join("..").join("assets").join("grammars");
    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("grammar_data.rs");

    println!("cargo:rerun-if-changed={}", grammars_dir.display());

    let mut entries: Vec<(String, String, PathBuf)> = Vec::new();
    for entry in fs::read_dir(&grammars_dir).expect("assets/grammars directory not found") {
        let path = entry.unwrap().path();
        if path.extension().and_then(|e| e.to_str()) != Some("json") {
            continue;
        }
        let id = path.file_stem().unwrap().to_str().unwrap().to_string();
        let contents = fs::read_to_string(&path).unwrap();
        let json: serde_json::Value =
            serde_json::from_str(&contents).unwrap_or_else(|e| panic!("invalid grammar {id}: {e}"));
        let scope_name = json
            .get("scopeName")
            .and_then(|v| v.as_str())
            .unwrap_or_else(|| panic!("grammar {id} has no scopeName"))
            .to_string();
        entries.push((id, scope_name, path));
    }
    entries.sort();

    let mut code = String::from(
        "/// (language id, root scope name, grammar JSON) for every bundled grammar.\n\
         pub static RAW_GRAMMARS: &[(&str, &str, &str)] = &[\n",
    );
    for (id, scope, path) in &entries {
        let path = path.canonicalize().unwrap();
        let path = path.to_str().unwrap().replace('\\', "/");
        code.push_str(&format!(
            "    ({id:?}, {scope:?}, include_str!({path:?})),\n"
        ));
    }
    code.push_str("];\n");

    fs::write(&out_path, code).unwrap();
}
