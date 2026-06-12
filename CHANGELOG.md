# Changelog

## [Unreleased]

### Changed
- Regenerated bindings against upstream naming-convention renames
  (libBeresta PR #64). Six functions renamed on the FFI surface:
  `BRST_Date_Now` → `BRST_Doc_Date_Now`,
  `BRST_Doc_Create_ExtGState` → `BRST_Doc_ExtGState_New`,
  `BRST_Doc_Pattern_Tiling_Create` → `BRST_Doc_Pattern_Tiling_New`
  (also in `DocPagePattern`),
  `BRST_Doc_XObject_Create` → `BRST_Doc_XObject_New`,
  `BRST_Page_CreateDestination` → `BRST_Page_Destination_New`.

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
