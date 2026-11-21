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

        INSTALL_URL = "https://github.com/libBeresta/brst-binding-ruby#install"

        # Message for the LoadError raised when FFI cannot open libbrst. FFI's
        # own message lists every path it tried but not what to do about it,
        # so lead with that and keep the original text at the end.
        def load_error_message(original)
          override = ENV["BRST_BINDING_RUBY_LIB"]
          advice =
            if override && !override.empty?
              "BRST_BINDING_RUBY_LIB is set to #{override.inspect}; check that it " \
                "points to libbrst.dylib / libbrst.so."
            else
              "This gem does not bundle libBeresta. Install libBeresta where the " \
                "system loader can find it, or set BRST_BINDING_RUBY_LIB to the path " \
                "of libbrst.dylib / libbrst.so."
            end

          [
            "brst-binding-ruby could not load the libBeresta shared library (libbrst).",
            advice,
            "See #{INSTALL_URL} for build steps.",
            "",
            "Original error: #{original}"
          ].join("\n")
        end
      end
    end
  end
end
