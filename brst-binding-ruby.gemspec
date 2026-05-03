require_relative "lib/brst/binding/ruby/version"

Gem::Specification.new do |spec|
  spec.name        = "brst-binding-ruby"
  spec.version     = Brst::Binding::Ruby::VERSION
  spec.authors     = ["Kenta Ishizaki"]
  spec.email       = ["kentaishizaki@55728.jp"]

  spec.summary     = "Low-level Ruby FFI bindings for libBeresta (PDF generation)"
  spec.description = <<~DESC
    Experimental Ruby FFI bindings for libBeresta, a free, cross-platform PDF
    generation C library forked from libHaru. Bindings are auto-generated from
    libBeresta's canonical S-expression definitions (gen/data/*.lsp). v0.1.0
    exposes a faithful low-level surface; an idiomatic high-level API is planned
    as a separate gem. Currently tested on macOS only; Linux support is planned
    for the next release. Part of the libBeresta org's brst-binding-<lang> family.
  DESC

  spec.homepage              = "https://github.com/libBeresta/brst-binding-ruby"
  spec.license               = "Zlib"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"]   = spec.homepage
  spec.metadata["bug_tracker_uri"]   = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"]     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "ext/extconf.rb",
    "CMakeLists.txt",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/extconf.rb"]

  spec.add_dependency "ffi", "~> 1.16"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rake",  "~> 13.2"
end
