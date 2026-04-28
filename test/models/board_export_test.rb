require "test_helper"

class BoardExportTest < ActiveSupport::TestCase
  setup do
    @board = boards(:one)
  end

  test "to_pdf returns a PDF byte string" do
    pdf = BoardExport.new(@board).to_pdf

    assert_kind_of String, pdf
    assert pdf.start_with?("%PDF"), "expected PDF header, got #{pdf[0, 20].inspect}"
  end

  test "to_pdf includes a page per problem plus cover" do
    pdf = BoardExport.new(@board).to_pdf

    # Parse page count from PDF trailer — crude but works for Prawn output
    page_count = pdf.scan(%r{/Type\s*/Page[^s]}).size
    expected = 1 + @board.problems.kept.count
    assert_equal expected, page_count
  end

  test "to_pdf handles board with no layout image" do
    board_layouts(:one).image_layout.purge if board_layouts(:one).image_layout.attached?

    pdf = BoardExport.new(@board).to_pdf
    assert pdf.start_with?("%PDF")
  end
end
