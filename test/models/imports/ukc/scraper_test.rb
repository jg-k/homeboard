require "test_helper"

class Imports::Ukc::ScraperTest < ActiveSupport::TestCase
  setup do
    @html = file_fixture("ukc_logbook.html").read
    @scraper = Imports::Ukc::Scraper.new("363619")
  end

  test "parses ascent rows and tags them with the supplied gear_style" do
    rows = @scraper.send(:parse_rows, @html, gear_style: "boulder")

    assert_equal 2, rows.size

    white_wine = rows.find { |r| r.route_name == "White Wine" }
    assert_equal "43768", white_wine.ukc_route_id
    assert_equal "f5", white_wine.grade
    assert_nil white_wine.quality
    assert_equal "Sent O/S", white_wine.ascent_type
    assert_equal "boulder", white_wine.gear_style
    assert_equal "Kyloe-in-the-woods (Kyloe-In)", white_wine.crag_name
    assert_equal Date.new(2026, 5, 6), white_wine.ascent_date.to_date

    magic_flute = rows.find { |r| r.route_name == "Magic Flute" }
    assert_equal "324", magic_flute.ukc_route_id
    assert_equal "E1 5b", magic_flute.grade
    assert_equal 2, magic_flute.quality
    assert_equal "Lead O/S", magic_flute.ascent_type
    assert_equal "boulder", magic_flute.gear_style
    assert_equal "Back Bowden Doors", magic_flute.crag_name
    assert_equal Date.new(2026, 1, 28), magic_flute.ascent_date.to_date
  end

  test "decrements year when month/day jumps forward (rows are date-desc)" do
    html = synthetic_logbook(2024, [ "5 Aug", "12 Mar", "20 Dec", "1 Feb" ])
    rows = @scraper.send(:parse_rows, html, gear_style: "trad")

    assert_equal [
      Date.new(2024, 8, 5),
      Date.new(2024, 3, 12),
      Date.new(2023, 12, 20),
      Date.new(2023, 2, 1)
    ], rows.map { |r| r.ascent_date.to_date }
    assert rows.all? { |r| r.gear_style == "trad" }
  end

  test "parse_grade_cell separates stars from grade" do
    assert_equal [ "E1 5b", 2 ], @scraper.send(:parse_grade_cell, "E1 5b **")
    assert_equal [ "f5", nil ], @scraper.send(:parse_grade_cell, "f5  ")
    assert_equal [ "7a", 3 ], @scraper.send(:parse_grade_cell, "7a ***")
    assert_equal [ nil, nil ], @scraper.send(:parse_grade_cell, "")
  end

  test "extract_route_id pulls trailing numeric id from href" do
    assert_equal "43768", @scraper.send(:extract_route_id, "/logbook/crags/kyloe-in-the-woods_kyloe-in-838/white_wine-43768")
    assert_nil @scraper.send(:extract_route_id, nil)
  end

  test "parse_date applies year when omitted" do
    assert_equal Date.new(2024, 5, 6), @scraper.send(:parse_date, "6 May", 2024).to_date
    assert_equal Date.new(2023, 1, 28), @scraper.send(:parse_date, "28th Jan 2023", 2024).to_date
    assert_nil @scraper.send(:parse_date, "", 2024)
  end

  private

  def synthetic_logbook(latest_year, dates)
    rows = dates.map.with_index do |date_text, i|
      <<~HTML
        <tr>
          <td class="climb"><a class="climbName" href="/logbook/crags/foo-1/route#{i}-#{1000 + i}">Route #{i}</a></td>
          <td class="grade">f6a</td>
          <td>Lead O/S</td>
          <td class="partner"></td>
          <td class="notes"></td>
          <td class="feedback"></td>
          <td class="logdate">#{date_text}</td>
          <td><a href="/logbook/crags/foo-1/">Foo</a></td>
        </tr>
      HTML
    end.join

    <<~HTML
      <html><body>
        <select name="year">
          <option></option>
          <option value="#{latest_year - 1}">#{latest_year - 1}</option>
          <option value="#{latest_year}">#{latest_year}</option>
        </select>
        <div id="myLogbookTable">
          <table><tbody>#{rows}</tbody></table>
        </div>
      </body></html>
    HTML
  end
end
