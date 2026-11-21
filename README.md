# brst-binding-ruby

[![CI](https://github.com/libBeresta/brst-binding-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/libBeresta/brst-binding-ruby/actions/workflows/ci.yml)

**Experimental, low-level Ruby FFI bindings for [libBeresta][libBeresta]**, a
free, cross-platform PDF generation C library forked from [libHaru][libHaru].

This is the Ruby member of the libBeresta org's `brst-binding-<lang>` family of
language bindings. Bindings are auto-generated from libBeresta's canonical
S-expression definitions in [`gen/data/*.lsp`][gen-data], so they stay faithful
to the upstream API.

## Status: v0.1.0 — experimental

- Auto-generated low-level FFI surface from `gen/data/*.lsp`. This release is
  generated from libBeresta 1.0.1.
- Tested in CI on macOS 14 and Ubuntu 24.04 with Ruby 3.2 – 3.4.
- An idiomatic, higher-level Ruby API is **not** part of this gem; that is
  planned as a separate gem on top of these low-level bindings.
- libBeresta itself is **not** bundled. The gem loads a `libbrst` shared
  library that you build and install separately (see below).

## Mandatory baseline

Per the libBeresta org-wide convention for `brst-binding-<lang>` repositories,
this repository ships:

- `README.md` (this file)
- `CMakeLists.txt` — entry point that builds libBeresta (vendored or external)
  into a shared library that the Ruby loader can `dlopen`.

Everything else (gemspec, `lib/`, `spec/`, generator, CI) follows Ruby
community conventions on top of that baseline.

## Quick start

### Install

```sh
gem install brst-binding-ruby
```

The gem does not ship libBeresta. Build libBeresta 1.0.1 as a shared library
and install it where the system loader can find it (`/usr/local` by default):

```sh
git clone --depth=1 --branch 1.0.1 https://github.com/libBeresta/libBeresta.git
cmake -S libBeresta -B libBeresta/build -DCMAKE_BUILD_TYPE=Release \
      -DLIBBRST_TESTS=OFF
cmake --build libBeresta/build -j
sudo cmake --install libBeresta/build
```

Alternatively, point the gem at an existing build by setting
`BRST_BINDING_RUBY_LIB=/path/to/libbrst.{dylib,so}` (see
[Library resolution](#library-resolution)).

### Development checkout

```sh
git clone https://github.com/libBeresta/brst-binding-ruby.git
cd brst-binding-ruby
git clone --depth=1 https://github.com/libBeresta/libBeresta.git ../libBeresta
# Native deps — macOS:
brew install cmake libpng
# Native deps — Ubuntu:
#   sudo apt-get install -y cmake libpng-dev zlib1g-dev pkg-config build-essential
bundle install
cmake -S . -B build -DLIBBRST_SOURCE_DIR=$(cd ../libBeresta && pwd) \
                    -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
bundle exec rspec
```

### Hello PDF in Ruby

```ruby
require "brst/binding/ruby"

include Brst::Binding::Ruby

pdf = Base.BRST_Doc_New(nil, nil)
page = DocPage.BRST_Doc_Page_Add(pdf)
PageRoutines.BRST_Page_SetSize(page, :A4, :PAGE_ORIENTATION_PORTRAIT)

font = DocFont.BRST_Doc_Font(pdf, "Helvetica", nil)
Text.BRST_Page_BeginText(page)
Text.BRST_Page_SetFontAndSize(page, font, 20.0)
Text.BRST_Page_MoveTextPos(page, 50.0, 750.0)
Text.BRST_Page_ShowText(page, "Hello, Beresta from Ruby!")
Text.BRST_Page_EndText(page)

DocSave.BRST_Doc_SaveToFile(pdf, "hello.pdf")
Base.BRST_Doc_Free(pdf)
```

## How it's built

```
libBeresta/gen/data/*.lsp          (S-expression — Source of Truth)
        │
        ▼
generator/bin/brst-binding-ruby-gen  (Ruby S-exp parser + FFI renderer)
        │
        ▼
lib/brst/binding/ruby/types.rb       (consolidated typedefs / enums / structs)
lib/brst/binding/ruby/<file>.rb      (one FFI module per .lsp file)
        │
        ▼
ext/libBeresta/lib/libbrst.{dylib,so}  (cmake-built native library)
```

The generator parses S-expressions directly. The `gen/json/*.json` files are
themselves auto-generated from the same `.lsp` files and are useful for
structural cross-checking but are **not** the source of truth.

To regenerate after pulling new `.lsp` data:

```sh
bundle exec rake generate
# or:
ruby generator/bin/brst-binding-ruby-gen \
  --data-dir ../libBeresta/gen/data \
  --out-dir  lib/brst/binding/ruby
```

CI guards against generator drift: the workflow regenerates on every push and
fails if the committed bindings differ from the generator's output.

## Library resolution

At load time, `Brst::Binding::Ruby::Library` searches in this order:

1. `ENV["BRST_BINDING_RUBY_LIB"]` — explicit override (path or library name).
2. `ext/libBeresta/lib/libbrst.{dylib,so}` — vendored build output.
3. `ext/libBeresta/build/src/libbrst.{dylib,so}` — in-tree cmake build output.
4. `build/libBeresta-build/src/libbrst.{dylib,so}` — alternative in-tree.
5. Falls back to `libbrst` / `brst` via the system loader.

If a function or type referenced by upstream `.lsp` data is absent from the
loaded native library (e.g. caption / C-symbol drift, or a feature compiled
out of this build), the corresponding `attach_function` is recorded in
`<Module>::MISSING_SYMBOLS` and the rest of the gem still loads.

## Releasing

Releases are published to rubygems.org by
[`.github/workflows/release.yml`](.github/workflows/release.yml) through
[Trusted Publishing][trusted-publishing]; no API token is stored in the
repository. To cut a release, bump `VERSION`, give the version a dated entry in
`CHANGELOG.md`, merge to `main`, then push a matching `v<version>` tag. The
workflow refuses to publish when the tag, `VERSION` and `CHANGELOG.md` disagree.

## Acknowledgements

- [@dmitrys99][dmitrys99] — libBeresta maintainer, designer of the S-expression
  source-of-truth pipeline, and gracious mentor for this binding effort. The
  `brst-binding-<lang>` org structure and the `README + CMakeLists.txt`
  baseline come from his guidance.
- [libHaru][libHaru] — original PDF C library this work ultimately descends
  from. Original copyright belongs to Takeshi Kanno and contributors.
- Russian-language docs in the upstream `.lsp` data are preserved verbatim in
  the parsed tree but not surfaced in v0.1.0 bindings.

## License

[zlib/libpng License](LICENSE) — same as libBeresta and libHaru.

[libBeresta]: https://github.com/libBeresta/libBeresta
[libHaru]: https://github.com/libharu/libharu
[gen-data]: https://github.com/libBeresta/libBeresta/tree/master/gen/data
[dmitrys99]: https://github.com/dmitrys99
[trusted-publishing]: https://guides.rubygems.org/trusted-publishing/
