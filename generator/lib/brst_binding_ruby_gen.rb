# frozen_string_literal: true

require "fileutils"
require_relative "brst_binding_ruby_gen/sexp_parser"
require_relative "brst_binding_ruby_gen/symbol_table"
require_relative "brst_binding_ruby_gen/renderer"

# Top-level orchestrator for the brst-binding-ruby code generator.
#
# Pipeline:
#   gen/data/*.lsp  --SexpParser-->  Ruby Hash/Array tree
#                   --SymbolTable--> consolidated type vocabulary
#                   --Renderer-->    types.rb + per-file FFI modules
#
# `types.rb` is emitted from the union of every file's type declarations
# (`:types`, `:pointers`, `:definitions`, `:enums`, `:structs`) so that the
# per-file modules need not depend on each other at load time.
module BrstBindingRubyGen
  module_function

  def run(data_dir:, out_dir:, lang: "en")
    data_dir = File.expand_path(data_dir)
    out_dir  = File.expand_path(out_dir)
    raise ArgumentError, "data dir does not exist: #{data_dir}" unless Dir.exist?(data_dir)

    FileUtils.mkdir_p(out_dir)

    lsp_files = Dir.glob(File.join(data_dir, "*.lsp")).sort
    raise "no .lsp files found in #{data_dir}" if lsp_files.empty?

    parsed = lsp_files.map do |path|
      tree = SexpParser.parse_file(path)
      [path, tree]
    end

    symbols = SymbolTable.from(parsed)

    # Emit consolidated types.rb first.
    File.write(File.join(out_dir, "types.rb"),
               Renderer.render_types(symbols, lang: lang))

    parsed.each do |path, tree|
      module_name = Renderer.module_name_from_filename(path)
      next if module_name.nil?

      body = Renderer.render_file(tree, symbols, lang: lang)
      next if body.nil? # nothing renderable in this file

      out_path = File.join(out_dir, "#{Renderer.snake_case(module_name)}.rb")
      File.write(out_path, body)
    end

    parsed.size
  end
end
