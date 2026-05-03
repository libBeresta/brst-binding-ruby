# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

# Smoke test mirroring libBeresta's demo/minimal.c. Verifies that:
#   1. The gem loads its generated FFI bindings.
#   2. The libBeresta shared library can be opened.
#   3. A trivial PDF round-trip (Doc_New -> Page_Add -> SetSize -> SaveToFile)
#      produces a non-empty PDF on disk.
#
# Skipped automatically when libBeresta has not been built locally; CI is
# responsible for building before running specs.
RSpec.describe "smoke: minimal PDF generation" do
  before(:all) do
    begin
      require "brst/binding/ruby"
    rescue LoadError, FFI::NotFoundError, RuntimeError => e
      skip "brst-binding-ruby could not load libBeresta: #{e.message}"
    end
  end

  let(:tmp_pdf) do
    File.join(Dir.mktmpdir("brst-binding-ruby-smoke"), "test.pdf")
  end

  it "writes 'Hello, Beresta from Ruby!' to an A4 portrait page" do
    base          = Brst::Binding::Ruby::Base
    doc_page      = Brst::Binding::Ruby::DocPage
    page_routines = Brst::Binding::Ruby::PageRoutines
    doc_save      = Brst::Binding::Ruby::DocSave
    doc_font      = Brst::Binding::Ruby::DocFont
    text          = Brst::Binding::Ruby::Text

    pdf = base.BRST_Doc_New(nil, nil)
    expect(pdf).not_to be_null

    begin
      page = doc_page.BRST_Doc_Page_Add(pdf)
      page_routines.BRST_Page_SetSize(page, :A4, :PAGE_ORIENTATION_PORTRAIT)

      font = doc_font.BRST_Doc_Font(pdf, "Helvetica", nil)
      expect(font).not_to be_null

      text.BRST_Page_BeginText(page)
      text.BRST_Page_SetFontAndSize(page, font, 20.0)
      text.BRST_Page_MoveTextPos(page, 50.0, 750.0)
      text.BRST_Page_ShowText(page, "Hello, Beresta from Ruby!")
      text.BRST_Page_EndText(page)

      status = doc_save.BRST_Doc_SaveToFile(pdf, tmp_pdf)
      expect(status).to eq(0)
    ensure
      base.BRST_Doc_Free(pdf)
    end

    expect(File.size(tmp_pdf)).to be > 100
    expect(File.read(tmp_pdf, 4)).to eq("%PDF")
  end

  it "generates a non-empty A4-landscape PDF (port of demo/minimal.c)" do
    base = Brst::Binding::Ruby::Base
    doc_page = Brst::Binding::Ruby::DocPage
    page_routines = Brst::Binding::Ruby::PageRoutines
    doc_save = Brst::Binding::Ruby::DocSave

    pdf = base.BRST_Doc_New(nil, nil)
    expect(pdf).not_to be_null

    begin
      page = doc_page.BRST_Doc_Page_Add(pdf)
      expect(page).not_to be_null

      status = page_routines.BRST_Page_SetSize(page, :A4, :PAGE_ORIENTATION_LANDSCAPE)
      expect(status).to eq(0)

      status = doc_save.BRST_Doc_SaveToFile(pdf, tmp_pdf)
      expect(status).to eq(0)
    ensure
      base.BRST_Doc_Free(pdf)
    end

    expect(File).to exist(tmp_pdf)
    expect(File.size(tmp_pdf)).to be > 100
    expect(File.read(tmp_pdf, 4)).to eq("%PDF")
  end

end
