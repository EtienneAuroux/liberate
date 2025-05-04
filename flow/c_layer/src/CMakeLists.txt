# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(c_layer_library VERSION 0.0.1 LANGUAGES C)

add_library(c_layer SHARED
  "c_layer.c"
)

set_target_properties(c_layer PROPERTIES
  PUBLIC_HEADER c_layer.h
  OUTPUT_NAME "c_layer"
  C_STANDARD 11
)

target_compile_definitions(c_layer PUBLIC DART_SHARED_LIB)
