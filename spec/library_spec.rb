# frozen_string_literal: true

require "spec_helper"
require "open3"
require "rbconfig"
require "brst/binding/ruby/library"

RSpec.describe Brst::Binding::Ruby::Library do
  def with_override(value)
    saved = ENV["BRST_BINDING_RUBY_LIB"]
    value.nil? ? ENV.delete("BRST_BINDING_RUBY_LIB") : ENV["BRST_BINDING_RUBY_LIB"] = value
    yield
  ensure
    saved.nil? ? ENV.delete("BRST_BINDING_RUBY_LIB") : ENV["BRST_BINDING_RUBY_LIB"] = saved
  end

  describe ".load_error_message" do
    it "explains that libBeresta is not bundled when no override is set" do
      message = with_override(nil) { described_class.load_error_message("dlopen failed") }

      expect(message).to start_with("brst-binding-ruby could not load the libBeresta shared library")
      expect(message).to include("does not bundle libBeresta")
      expect(message).to include("set BRST_BINDING_RUBY_LIB")
      expect(message).to end_with("Original error: dlopen failed")
    end

    it "points at the override when BRST_BINDING_RUBY_LIB is set" do
      message = with_override("/opt/nowhere/libbrst.so") { described_class.load_error_message("dlopen failed") }

      expect(message).to include('BRST_BINDING_RUBY_LIB is set to "/opt/nowhere/libbrst.so"')
      expect(message).not_to include("does not bundle libBeresta")
    end
  end

  # Runs in a child process: a library that fails to open must not leave this
  # process with half-loaded FFI modules.
  it "raises that message when the gem is required and libbrst cannot be opened" do
    missing = File.join(Dir.tmpdir, "brst-binding-ruby-no-such-dir", "libbrst.so")
    script = <<~RUBY
      begin
        require "brst/binding/ruby"
        puts "LOADED"
      rescue LoadError => e
        puts e.message
      end
    RUBY
    output, status = Open3.capture2e(
      { "BRST_BINDING_RUBY_LIB" => missing },
      RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), "-e", script
    )

    expect(status).to be_success, output
    expect(output).to start_with("brst-binding-ruby could not load the libBeresta shared library")
    expect(output).to include("BRST_BINDING_RUBY_LIB is set to #{missing.inspect}")
    expect(output).to include("Original error: Could not open library")
  end
end
