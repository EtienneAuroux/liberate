# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flow_board_library VERSION 0.0.1 LANGUAGES C)

add_library(flow_board SHARED
  "flow_board.c"
)

set_target_properties(flow_board PROPERTIES
  PUBLIC_HEADER flow_board.h
  OUTPUT_NAME "flow_board"
)

target_compile_definitions(flow_board PUBLIC DART_SHARED_LIB)
