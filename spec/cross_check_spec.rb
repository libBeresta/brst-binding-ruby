# frozen_string_literal: true

require "spec_helper"
require "json"

# Structural cross-check: our S-expression parser must produce the same
# function / enum / pointer / definition / struct counts as libBeresta's
# auto-generated JSON view of the same .lsp data (`gen/json/*.json`,
# emitted by ECL+Djula). The JSON form is a derived artifact — we don't
# *depend* on it (Source of Truth is .lsp), but for v0.1.0 sanity it is a
# useful structural check to ensure our parser hasn't dropped or duplicated
# any top-level entity.
#
# Skipped automatically when libBeresta is not cloned at ../libBeresta.
RSpec.describe "structural cross-check vs gen/json" do
  let(:data_dir) { File.expand_path("../../libBeresta/gen/data", __dir__) }
  let(:json_dir) { File.expand_path("../../libBeresta/gen/json", __dir__) }

  before do
    skip "libBeresta sibling clone not present" unless Dir.exist?(data_dir) && Dir.exist?(json_dir)
    require_relative "../generator/lib/brst_binding_ruby_gen"
  end

  it "matches function/enum/pointer/struct counts per file" do
    diffs = []

    Dir.glob(File.join(json_dir, "*.json")).sort.each do |jpath|
      base = File.basename(jpath, ".json")
      lpath = File.join(data_dir, "#{base}.lsp")
      next unless File.exist?(lpath)

      json_tree = JSON.parse(File.read(jpath))
      lsp_tree  = BrstBindingRubyGen::SexpParser.parse_file(lpath)

      %w[functions enums pointers definitions structs consts sizes].each do |key|
        json_count = (json_tree[key] || []).size
        lsp_count  = (Array(lsp_tree[key.to_sym])).size
        if json_count != lsp_count
          diffs << "#{base}.#{key}: json=#{json_count} lsp_parser=#{lsp_count}"
        end
      end
    end

    expect(diffs).to be_empty, "mismatched counts:\n  #{diffs.join("\n  ")}"
  end
end
