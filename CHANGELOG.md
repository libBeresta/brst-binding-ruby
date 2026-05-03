# Changelog

## [Unreleased]

## [0.1.0] - TBD (pending libBeresta 1.0.0 release)

Initial experimental release.

### Added
- Low-level FFI bindings auto-generated from libBeresta's canonical
  S-expression definitions (`gen/data/*.lsp`).
- S-expression parser and Ruby FFI renderer in `generator/`.
- Smoke test that generates a PDF on macOS.
- mandatory baseline: README.md + CMakeLists.txt at repository root
  (per libBeresta org-wide `brst-binding-<lang>` family convention).

### Known limitations
- macOS only. Linux support planned for the next release.
- Low-level surface only. An idiomatic high-level API is planned as a
  separate gem.

[0.1.0]: https://github.com/libBeresta/brst-binding-ruby/releases/tag/v0.1.0
