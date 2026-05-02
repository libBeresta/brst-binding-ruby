# frozen_string_literal: true

require "strscan"

module BrstBindingRubyGen
  # Minimal Common-Lisp-flavoured S-expression parser tuned for libBeresta's
  # gen/data/*.lsp files. Recognises:
  #   - lists `( ... )`
  #   - strings `"..."` with `\"` `\\` `\n` escapes (and tolerates raw newlines)
  #   - `:keyword` symbols
  #   - integers (`0x00`, `123`), floats (`3.14`)
  #   - bare identifiers (with `-`, `_`, `*`, alpha-num)
  #   - `;` line comments
  #
  # When a list looks like a property list `(:k1 v1 :k2 v2 ...)` it is converted
  # into a Ruby Hash keyed by Symbol. Otherwise it stays an Array.
  module SexpParser
    module_function

    Sym = Struct.new(:name) do
      def to_s
        name
      end

      def inspect
        ":#{name}"
      end
    end

    Bare = Struct.new(:name) do
      def to_s
        name
      end

      def inspect
        name
      end
    end

    def parse_file(path)
      parse(File.read(path, encoding: "UTF-8"))
    end

    def parse(source)
      sc = StringScanner.new(source)
      result = read_form(sc)
      skip_ws_and_comments(sc)
      # Be lenient about a stray trailing `)` (encrypt.lsp ships with one
      # extra close paren upstream). Warn but don't fail the whole pipeline.
      while sc.peek(1) == ")"
        warn "[brst-binding-ruby-gen] ignoring stray ')' at byte #{sc.pos}"
        sc.getch
        skip_ws_and_comments(sc)
      end
      raise "trailing content at offset #{sc.pos}" unless sc.eos?
      plist_to_hash(result)
    end

    def read_form(sc)
      skip_ws_and_comments(sc)
      raise "unexpected EOF" if sc.eos?

      case sc.peek(1)
      when "("
        sc.getch
        read_list(sc)
      when ")"
        raise "unexpected ')' at #{sc.pos}"
      when '"'
        read_string(sc)
      when ":"
        read_keyword(sc)
      else
        read_atom(sc)
      end
    end

    def read_list(sc)
      items = []
      loop do
        skip_ws_and_comments(sc)
        raise "unterminated list" if sc.eos?
        if sc.peek(1) == ")"
          sc.getch
          return items
        end
        items << read_form(sc)
      end
    end

    def read_string(sc)
      sc.getch # consume opening quote
      buf = +""
      loop do
        raise "unterminated string at #{sc.pos}" if sc.eos?
        ch = sc.getch
        if ch == '"'
          return buf
        elsif ch == "\\"
          esc = sc.getch
          buf << case esc
                 when "n"  then "\n"
                 when "t"  then "\t"
                 when "r"  then "\r"
                 when '"'  then '"'
                 when "\\" then "\\"
                 when "c"  then "\\c" # Doxygen \c — keep verbatim
                 else "\\#{esc}"
                 end
        else
          buf << ch
        end
      end
    end

    # Permissive keyword: anything after `:` until whitespace / paren / quote /
    # comment. Some libBeresta .lsp files mistakenly use Cyrillic letters in
    # keyword names (e.g. `:ру` in doc_font.lsp instead of `:ru`); we don't
    # want to crash on those — we just expose them as-is.
    KEYWORD_RE = /:[^\s()";]+/.freeze
    ATOM_RE    = /[^\s()";]+/.freeze

    def read_keyword(sc)
      tok = sc.scan(KEYWORD_RE) or raise "bad keyword at #{sc.pos}"
      Sym.new(tok[1..])
    end

    def read_atom(sc)
      tok = sc.scan(ATOM_RE) or raise "bad atom at #{sc.pos}: #{sc.peek(20).inspect}"
      classify_atom(tok)
    end

    def classify_atom(tok)
      case tok
      when /\A-?0x[0-9A-Fa-f]+\z/ then Integer(tok, 16)
      when /\A-?\d+\z/            then tok.to_i
      when /\A-?\d+\.\d+(?:[eE][+-]?\d+)?\z/ then tok.to_f
      when "T", "t" then true
      when "NIL", "nil" then nil
      else Bare.new(tok)
      end
    end

    def skip_ws_and_comments(sc)
      loop do
        sc.skip(/\s+/)
        if sc.peek(1) == ";"
          sc.skip(/[^\n]*/)
        else
          break
        end
      end
    end

    # If `arr` is a property list `(:k v :k v ...)` (even-length, every other
    # element is a Sym), convert to Hash. Otherwise recurse and return Array.
    def plist_to_hash(arr)
      return arr unless arr.is_a?(Array)

      converted = arr.map { |e| plist_to_hash(e) }

      if converted.length.even? && converted.length.positive? &&
         converted.each_slice(2).all? { |k, _| k.is_a?(Sym) }
        h = {}
        converted.each_slice(2) { |k, v| h[k.name.to_sym] = v }
        h
      else
        converted
      end
    end
  end
end
