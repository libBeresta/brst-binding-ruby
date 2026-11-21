# frozen_string_literal: true

require "spec_helper"
require "open3"
require "rbconfig"

# Checks on the committed generator output itself. These need neither a
# libBeresta checkout nor a built libbrst.
RSpec.describe "generated bindings" do
  let(:binding_dir) { File.expand_path("../lib/brst/binding/ruby", __dir__) }

  it "parse without warnings under ruby -w" do
    files = Dir[File.join(binding_dir, "*.rb")].sort
    script = "ARGV.each { |f| RubyVM::InstructionSequence.compile_file(f) }"
    output, status = Open3.capture2e(RbConfig.ruby, "-w", "-e", script, *files)

    expect(status).to be_success, output
    expect(output).to eq("")
  end

  it "register each typedef only once" do
    typedefs = File.readlines(File.join(binding_dir, "types.rb"))
                   .grep(/^\s+mod\.typedef /)
                   .map(&:strip)

    expect(typedefs.tally.select { |_, count| count > 1 }).to be_empty
  end
end
