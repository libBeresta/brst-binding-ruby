# Changelog

## [0.1.0] - 2026-11-21

Initial experimental release.

### Added
- Low-level FFI bindings auto-generated from libBeresta's canonical
  S-expression definitions (`gen/data/*.lsp`), generated from libBeresta 1.0.1.
- S-expression parser and Ruby FFI renderer in `generator/`.
- Smoke tests that generate PDFs, run in CI on macOS 14 and Ubuntu 24.04.
- mandatory baseline: README.md + CMakeLists.txt at repository root
  (per libBeresta org-wide `brst-binding-<lang>` family convention).
- Release workflow that publishes to rubygems.org through Trusted Publishing
  when a `v<version>` tag is pushed.

### Known limitations
- Low-level surface only. An idiomatic high-level API is planned as a
  separate gem.
- libBeresta is not bundled. A `libbrst` shared library must be built and
  installed separately (see README).

[0.1.0]: https://github.com/libBeresta/brst-binding-ruby/releases/tag/v0.1.0
