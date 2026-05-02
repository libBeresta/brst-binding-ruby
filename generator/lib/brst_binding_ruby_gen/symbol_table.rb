# frozen_string_literal: true

module BrstBindingRubyGen
  # Aggregates all type vocabulary from every parsed .lsp file:
  #   - inner→outer scalar mappings from types.lsp
  #   - opaque pointers (`:pointers`)
  #   - aliases (`:definitions`)
  #   - enums (`:enums`)
  #   - structs (`:structs`)
  #   - hex/decimal constants (`:consts`)
  #   - page-size table (`:sizes` from page_sizes.lsp)
  #
  # Used both by the renderer (to emit types.rb) and to resolve function
  # parameter / result types across files.
  class SymbolTable
    DEFAULT_INNER_MAP = {
      "void"   => :void
    }.freeze

    attr_reader :inner_to_ffi, :pointers, :definitions, :enums, :structs, :consts, :sizes,
                :enum_lookup_by_value

    def self.from(parsed_files)
      st = new
      parsed_files.each { |_path, tree| st.absorb(tree) }
      st.finalize!
      st
    end

    def initialize
      @inner_to_ffi = DEFAULT_INNER_MAP.dup
      @pointers     = {} # name(String) -> {name:}
      @definitions  = {} # name(String) -> {name:, original:}
      @enums        = {} # name(String) -> {name:, elements: [{element:, value:}]}
      @structs      = {} # name(String) -> {name:, fields: [{field:, type:}]}
      @consts       = {} # name(String) -> {name:, value:, en?, ru?}
      @sizes        = []
      @enum_lookup_by_value = {} # value(Integer) -> [enum_name, element]
    end

    def absorb(tree)
      return unless tree.is_a?(Hash)

      absorb_types(tree[:types])           if tree[:types]
      absorb_pointers(tree[:pointers])     if tree[:pointers]
      absorb_definitions(tree[:definitions]) if tree[:definitions]
      absorb_enums(tree[:enums])           if tree[:enums]
      absorb_structs(tree[:structs])       if tree[:structs]
      absorb_consts(tree[:consts])         if tree[:consts]
      absorb_sizes(tree[:sizes])           if tree[:sizes]
    end

    # Resolve a libBeresta type name to a Ruby FFI type (Symbol).
    # Falls back to `:pointer` for unknown `T*` names.
    def resolve(raw)
      return :void if raw.nil?
      n = raw.to_s.strip

      if (mapped = @inner_to_ffi[n])
        return mapped
      end

      # Hyphen↔underscore equivalence for inner mappings.
      under = n.tr("-", "_")
      hy    = n.tr("_", "-")
      [under, hy].each do |alt|
        return @inner_to_ffi[alt] if @inner_to_ffi.key?(alt)
      end

      # Pointer-suffix fallback: `BYTE*`, `Foo*` → :pointer
      if n.end_with?("*")
        return :pointer
      end

      # Anything else: assume a typedef'd FFI symbol matching the name itself.
      n.to_sym
    end

    # All type names that get emitted as `typedef ..., :Name` in types.rb,
    # in dependency order (types.lsp inner names first, then pointers,
    # definitions, enums, structs).
    def emitted_typedefs
      out = []
      @inner_to_ffi.each do |inner, ffi|
        next if inner == "void"
        out << [inner, :scalar, ffi]
      end
      @pointers.each_key   { |n| out << [n, :pointer, :pointer] }
      @definitions.each   { |n, d| out << [n, :alias, d[:original]] }
      out
    end

    def finalize!
      # Merge `_`/`-` variants so resolution is symmetric (Doc_New uses
      # "Error_Handler" while types.lsp registers "Error-Handler").
      additions = {}
      @inner_to_ffi.each do |inner, ffi|
        next if inner == "void"
        under = inner.tr("-", "_")
        additions[under] = ffi unless @inner_to_ffi.key?(under)
        hy = inner.tr("_", "-")
        additions[hy] = ffi unless @inner_to_ffi.key?(hy)
      end
      @inner_to_ffi.merge!(additions)
    end

    private

    def absorb_types(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        inner = row[:inner].to_s
        outer = row[:outer].to_s
        @inner_to_ffi[inner] = outer_to_ffi_symbol(outer)
      end
    end

    def outer_to_ffi_symbol(outer)
      case outer
      when "string"  then :string
      when "pointer" then :pointer
      when "void"    then :void
      when /\Aint(8|16|32|64)?\z/, /\Auint(8|16|32|64)?\z/ then outer.to_sym
      when "float"   then :float
      when "double"  then :double
      when "size_t"  then :size_t
      when "bool"    then :bool
      else outer.to_sym
      end
    end

    def absorb_pointers(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        name = row[:name].to_s
        @pointers[name] = { name: name }
      end
    end

    def absorb_definitions(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        name = row[:name].to_s
        original = row[:original].to_s
        @definitions[name] = { name: name, original: original }
      end
    end

    def absorb_enums(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        name = row[:name].to_s
        elements = Array(row[:elements]).map do |el|
          {
            element: el[:element].to_s,
            value:   parse_numeric(el[:value]),
            en:      el[:en].to_s,
            ru:      el[:ru].to_s
          }
        end
        @enums[name] = { name: name, elements: elements, en: row[:en].to_s, ru: row[:ru].to_s }
        elements.each do |el|
          next if el[:value].nil?
          @enum_lookup_by_value[[name, el[:value]]] = el
        end
      end
    end

    def absorb_structs(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        name = row[:name].to_s
        fields = Array(row[:fields]).map do |f|
          { field: f[:field].to_s, type: f[:type].to_s, en: f[:en].to_s, ru: f[:ru].to_s }
        end
        @structs[name] = { name: name, fields: fields, en: row[:en].to_s, ru: row[:ru].to_s }
      end
    end

    def absorb_consts(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        name = row[:name].to_s
        @consts[name] = { name: name, value: row[:value], en: row[:en].to_s, ru: row[:ru].to_s }
      end
    end

    def absorb_sizes(rows)
      Array(rows).each do |row|
        next unless row.is_a?(Hash)
        @sizes << {
          caption: row[:caption].to_s,
          id:      row[:id].to_s,
          origin:  row[:origin].to_s,
          width:   row[:width].to_f,
          height:  row[:height].to_f
        }
      end
      synthesize_page_sizes_enum!
    end

    # `PageSizes` is referenced by functions in base.lsp and page_routines.lsp,
    # but the .lsp files never declare it as an :enum. Upstream's C header
    # `brst_page_sizes_iso_216.h` (used when LIBBRST_ISO_216_ONLY=ON, the
    # default build mode) auto-numbers ISO 216 entries from 0 in the same
    # source order they appear in page_sizes.lsp. Synthesise the matching
    # FFI enum so callers can pass `:A4` instead of a magic integer.
    def synthesize_page_sizes_enum!
      iso216 = @sizes.select { |s| s[:origin] == "ISO 216" }
      return if iso216.empty?
      elements = iso216.each_with_index.map do |s, i|
        { element: s[:id], value: i, en: "", ru: "" }
      end
      elements << { element: "EOF", value: iso216.size, en: "", ru: "" }
      @enums["PageSizes"] = {
        name: "PageSizes",
        elements: elements,
        en: "ISO 216 page size enum (synthesised from page_sizes.lsp).",
        ru: ""
      }
    end

    def parse_numeric(v)
      return nil if v.nil?
      return v if v.is_a?(Numeric)
      s = v.to_s.strip
      return nil if s.empty?
      if s =~ /\A-?0x[0-9A-Fa-f]+\z/
        Integer(s, 16)
      elsif s =~ /\A-?\d+\z/
        s.to_i
      elsif s =~ /\A-?\d+\.\d+/
        s.to_f
      else
        s
      end
    end
  end
end
