# frozen_string_literal: true

require "ffi"

module Brst
  module Binding
    module Ruby
      # Locates libBeresta's shared library so generated FFI modules can call
      # `ffi_lib Brst::Binding::Ruby::Library.lib_path`.
      #
      # Resolution order:
      #   1. ENV["BRST_BINDING_RUBY_LIB"]   — explicit override (any path or name)
      #   2. ext/libBeresta/lib/libbrst.{dylib,so}     (vendored build output)
      #   3. ext/libBeresta/build/src/libbrst.{dylib,so} (in-tree build output)
      #   4. "brst" / "libbrst" — let ffi/dlopen search system paths
      module Library
        module_function

        def lib_path
          @lib_path ||= resolve!
        end

        def resolve!
          if (override = ENV["BRST_BINDING_RUBY_LIB"]) && !override.empty?
            return override
          end

          candidates = []
          gem_root = File.expand_path("../../../..", __dir__)

          %w[dylib so].each do |ext|
            candidates << File.join(gem_root, "ext", "libBeresta", "lib", "libbrst.#{ext}")
            candidates << File.join(gem_root, "ext", "libBeresta", "build", "src", "libbrst.#{ext}")
            candidates << File.join(gem_root, "build", "libBeresta-build", "src", "libbrst.#{ext}")
          end

          found = candidates.find { |p| File.exist?(p) }
          return found if found

          # Fall back to library names; FFI will search system paths.
          %w[brst libbrst]
        end
      end
    end
  end
end
