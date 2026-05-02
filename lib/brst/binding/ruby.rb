# frozen_string_literal: true

require_relative "ruby/version"
require_relative "ruby/library"
require_relative "ruby/types"

module Brst
  module Binding
    # Top-level entrypoint for brst-binding-ruby.
    #
    # Generated FFI modules live under Brst::Binding::Ruby::<File>, e.g.
    #   Brst::Binding::Ruby::Base.BRST_Doc_New(...)
    #   Brst::Binding::Ruby::DocSave.BRST_Doc_SaveToFile(pdf, "out.pdf")
    #
    # The naming follows libBeresta's gen/data/*.lsp file boundaries; this is a
    # faithful low-level surface, not an idiomatic Ruby API. A higher-level
    # wrapper gem is planned separately.
    module Ruby
    end
  end
end

# Auto-load every generated FFI module. Order is irrelevant because every type
# (pointer/enum/struct/definition) is centralized in `types.rb`, which has
# already been loaded above.
Dir[File.expand_path("ruby/*.rb", __dir__)].sort.each do |f|
  base = File.basename(f, ".rb")
  next if %w[version library types].include?(base)
  require f
end
