#include "oniguruma.h"

__attribute__((visibility("default"))) __attribute__((used))
void* syntax_highlighter_plus_force_load() {
    void* ptrs[] = {
        (void*)onig_initialize,
        (void*)onig_new,
        (void*)onig_search,
        (void*)onig_free,
        (void*)onig_region_new,
        (void*)onig_region_free,
        (void*)onig_error_code_to_str,
        (void*)&OnigEncodingUTF8,
        (void*)&OnigDefaultSyntax
    };
    return ptrs;
}
