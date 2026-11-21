# frozen_string_literal: true

require "spec_helper"
require_relative "../generator/lib/brst_binding_ruby_gen"

RSpec.describe BrstBindingRubyGen do
  around do |example|
    Dir.mktmpdir("brst-binding-ruby-gen") do |dir|
      @data_dir = File.join(dir, "data")
      @out_dir  = File.join(dir, "out")
      FileUtils.mkdir_p([@data_dir, @out_dir])
      example.run
    end
  end

  def write_lsp(name)
    File.write(File.join(@data_dir, "#{name}.lsp"), <<~LSP)
      (:file "#{name}"
       :functions ((:caption "Doc_#{name.capitalize}"
                    :params ((:name "pdf" :type "Doc"))
                    :result (:type "STATUS"))))
    LSP
  end

  def output_files
    Dir.children(@out_dir).sort
  end

  it "removes modules whose .lsp file is gone and keeps hand-written files" do
    write_lsp("alpha")
    write_lsp("beta")
    File.write(File.join(@out_dir, "library.rb"), "# hand-written\n")

    described_class.run(data_dir: @data_dir, out_dir: @out_dir)
    expect(output_files).to eq(%w[alpha.rb beta.rb library.rb types.rb])

    File.delete(File.join(@data_dir, "beta.lsp"))
    expect { described_class.run(data_dir: @data_dir, out_dir: @out_dir) }
      .to output(/removed stale beta\.rb/).to_stderr

    expect(output_files).to eq(%w[alpha.rb library.rb types.rb])
  end
end
