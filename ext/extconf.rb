require "mkmf"
require "fileutils"

# brst-binding-ruby ext/extconf.rb
#
# This file is **not** a traditional C extension build script. brst-binding-ruby
# is a pure-Ruby FFI gem; the native dependency is libBeresta, an external
# shared library. We declare an extension only so that `gem install` runs this
# file, giving us a hook to either:
#
#   - Build libBeresta from a vendored source tree (ext/libBeresta/), or
#   - Skip the build and rely on a system-installed libbrst.
#
# A no-op Makefile is always emitted so RubyGems considers the build successful.

ROOT      = File.expand_path("..", __dir__)
EXT_DIR   = File.join(ROOT, "ext", "libBeresta")
SRC_CMAKE = File.join(EXT_DIR, "CMakeLists.txt")
LIB_OUT   = File.join(EXT_DIR, "lib")

def have_cmake?
  system("cmake --version > /dev/null 2>&1")
end

def build_libbrst
  build_dir = File.join(EXT_DIR, "build")
  FileUtils.mkdir_p(build_dir)
  FileUtils.mkdir_p(LIB_OUT)

  Dir.chdir(ROOT) do
    sh = ->(*cmd) { system(*cmd) || abort("[brst-binding-ruby] command failed: #{cmd.join(' ')}") }
    sh.call("cmake", "-S", ".", "-B", "build",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLIBBRST_SOURCE_DIR=#{EXT_DIR}")
    sh.call("cmake", "--build", "build", "--config", "Release")
  end
end

if File.exist?(SRC_CMAKE)
  if have_cmake?
    build_libbrst
  else
    warn "[brst-binding-ruby] cmake not found; skipping libBeresta build. " \
         "Install cmake or set BRST_BINDING_RUBY_LIB to an existing libbrst path."
  end
else
  warn "[brst-binding-ruby] ext/libBeresta source not vendored; skipping build. " \
       "Set BRST_BINDING_RUBY_LIB to an existing libbrst, or vendor the source."
end

# Always emit a stub Makefile so `gem install` succeeds.
File.write(File.join(__dir__, "Makefile"), <<~MAKE)
  all:
  \t@true
  install:
  \t@true
  clean:
  \t@true
MAKE
