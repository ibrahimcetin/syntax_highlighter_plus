cmake_minimum_required(VERSION 3.10)
project(syntax_highlighter_plus_shared)

# Configure oniguruma options
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries" FORCE)
set(BUILD_TEST OFF CACHE BOOL "Build tests" FORCE)
set(INSTALL_DOCUMENTATION OFF CACHE BOOL "Install documentation" FORCE)

add_subdirectory(oniguruma-6.9.10)

# Flutter's plugin tool expects a target named after the plugin.
# Oniguruma creates a target named "onig". We rename the output and create an alias.
set_target_properties(onig PROPERTIES OUTPUT_NAME "syntax_highlighter_plus")
add_library(syntax_highlighter_plus ALIAS onig)
