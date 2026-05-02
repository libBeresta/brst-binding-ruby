# brst-binding-ruby — mandatory baseline build entry point
#
# This CMakeLists.txt fulfils the libBeresta org-wide baseline for
# `brst-binding-<lang>` repositories (README + CMakeLists.txt). It exists to
# build the libBeresta shared library so that the Ruby FFI bindings can load
# it at runtime.
#
# Two modes are supported:
#
# 1. Vendored source mode (preferred for `gem install`):
#      Drop libBeresta source into ext/libBeresta/ (e.g. via git submodule or
#      tarball) and build from this directory:
#          cmake -S . -B build
#          cmake --build build
#
# 2. External source mode (development convenience):
#      Pass -DLIBBRST_SOURCE_DIR=/path/to/libBeresta clone:
#          cmake -S . -B build -DLIBBRST_SOURCE_DIR=$HOME/src/libBeresta
#          cmake --build build
#
# The resulting shared library (libbrst.dylib / libbrst.so) is copied into
# ext/libBeresta/lib/ where the Ruby loader looks for it.

cmake_minimum_required(VERSION 3.16)
project(brst_binding_ruby NONE)

set(_default_libbrst_src "${CMAKE_CURRENT_LIST_DIR}/ext/libBeresta")
set(LIBBRST_SOURCE_DIR "${_default_libbrst_src}" CACHE PATH
    "Path to libBeresta source tree to build (defaults to ext/libBeresta)")

if(NOT EXISTS "${LIBBRST_SOURCE_DIR}/CMakeLists.txt")
    message(WARNING
        "libBeresta source not found at ${LIBBRST_SOURCE_DIR}.\n"
        "Either:\n"
        "  - Place libBeresta source in ext/libBeresta/ (e.g. git submodule), or\n"
        "  - Pass -DLIBBRST_SOURCE_DIR=/path/to/libBeresta\n"
        "Skipping libBeresta build target.")
    return()
endif()

enable_language(C)

set(LIBBRST_SHARED_LIB ON CACHE BOOL "" FORCE)
set(LIBBRST_EXAMPLES   OFF CACHE BOOL "" FORCE)
set(LIBBRST_TESTS      OFF CACHE BOOL "" FORCE)

add_subdirectory("${LIBBRST_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/libBeresta-build")

set(_outdir "${CMAKE_CURRENT_LIST_DIR}/ext/libBeresta/lib")
file(MAKE_DIRECTORY "${_outdir}")

add_custom_target(brst_binding_ruby_stage ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:brst>
            "${_outdir}/libbrst${CMAKE_SHARED_LIBRARY_SUFFIX}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:brst>
            "${_outdir}/$<TARGET_FILE_NAME:brst>"
    DEPENDS brst
    COMMENT "Staging libbrst shared library into ext/libBeresta/lib/")
