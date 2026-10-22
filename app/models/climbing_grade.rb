# Puts outdoor grades from any system on one scale per discipline, so ascents
# logged in different systems can be counted side by side: Font for boulders,
# French for sport and trad routes. Conversions follow the usual comparison tables and pick
# the lower grade where one grade spans two. A grade we cannot read comes back
# nil.
#
#   ClimbingGrade.normalize("V5", discipline: :boulder)    # => "6C"
#   ClimbingGrade.normalize("E1 5b", discipline: :trad)    # => "5c"
#   ClimbingGrade.normalize("5.11a", discipline: :sport)   # => "6b+"
module ClimbingGrade
  FONT = %w[3 4A 4B 4C 5A 5B 5C 6A 6A+ 6B 6B+ 6C 6C+ 7A 7A+ 7B 7B+ 7C 7C+ 8A 8A+ 8B 8B+ 8C 8C+ 9A].freeze
  FRENCH = %w[1 2 3 4a 4b 4c 5a 5b 5c 6a 6a+ 6b 6b+ 6c 6c+ 7a 7a+ 7b 7b+ 7c 7c+
              8a 8a+ 8b 8b+ 8c 8c+ 9a 9a+ 9b 9b+ 9c].freeze
  SCALES = { boulder: FONT, sport: FRENCH, trad: FRENCH }.freeze

  V_TO_FONT = {
    "B" => "3", "0" => "4A", "1" => "5A", "2" => "5C", "3" => "6A", "4" => "6B", "5" => "6C",
    "6" => "7A", "7" => "7A+", "8" => "7B", "9" => "7C", "10" => "7C+", "11" => "8A",
    "12" => "8A+", "13" => "8B", "14" => "8B+", "15" => "8C", "16" => "8C+", "17" => "9A"
  }.freeze

  # Adjectival grade only: the technical grade after it says how hard the
  # hardest move is, not the route.
  BRITISH_TO_FRENCH = {
    "M" => "1", "D" => "2", "VD" => "3", "HVD" => "3", "MS" => "4a", "S" => "4a",
    "HS" => "4b", "MVS" => "4c", "VS" => "4c", "HVS" => "5b", "E1" => "5c", "E2" => "6a+",
    "E3" => "6b", "E4" => "6c", "E5" => "7a", "E6" => "7b", "E7" => "7c", "E8" => "8a",
    "E9" => "8b", "E10" => "8c", "E11" => "9a"
  }.freeze

  UIAA_TO_FRENCH = {
    "3" => "3", "4-" => "4a", "4" => "4a", "4+" => "4b", "5-" => "4c", "5" => "5a",
    "5+" => "5b", "6-" => "5c", "6" => "5c", "6+" => "6a", "7-" => "6a+", "7" => "6b+",
    "7+" => "6c", "8-" => "6c+", "8" => "7a+", "8+" => "7b", "9-" => "7b+", "9" => "7c+",
    "9+" => "8a", "10-" => "8b", "10" => "8b+", "10+" => "8c", "11-" => "8c+", "11" => "9a",
    "11+" => "9a+", "12-" => "9b"
  }.freeze
  ROMAN = { "I" => 1, "II" => 2, "III" => 3, "IV" => 4, "V" => 5, "VI" => 6, "VII" => 7,
            "VIII" => 8, "IX" => 9, "X" => 10, "XI" => 11, "XII" => 12 }.freeze

  YDS_TO_FRENCH = {
    "5.5" => "4a", "5.6" => "4b", "5.7" => "4c", "5.8" => "5b", "5.9" => "5c",
    "5.10a" => "6a", "5.10b" => "6a+", "5.10c" => "6b", "5.10d" => "6b+",
    "5.11a" => "6b+", "5.11b" => "6c", "5.11c" => "6c+", "5.11d" => "7a",
    "5.12a" => "7a+", "5.12b" => "7b", "5.12c" => "7b+", "5.12d" => "7c",
    "5.13a" => "7c+", "5.13b" => "8a", "5.13c" => "8a+", "5.13d" => "8b",
    "5.14a" => "8b+", "5.14b" => "8c", "5.14c" => "8c+", "5.14d" => "9a",
    "5.15a" => "9a+", "5.15b" => "9b", "5.15c" => "9b+", "5.15d" => "9c"
  }.freeze

  EWBANK_TO_FRENCH = {
    12 => "4a", 13 => "4b", 14 => "4c", 15 => "5a", 16 => "5b", 17 => "5c", 18 => "6a",
    19 => "6a+", 20 => "6b", 21 => "6b+", 22 => "6c", 23 => "7a", 24 => "7a+", 25 => "7b",
    26 => "7b+", 27 => "7c+", 28 => "8a", 29 => "8a+", 30 => "8b", 31 => "8b+", 32 => "8c",
    33 => "8c+", 34 => "9a", 35 => "9a+", 36 => "9b", 37 => "9b+", 38 => "9c"
  }.freeze

  # Low Font grades are written with or without a letter: 4+ and 5+ sit at
  # the top of their number.
  BARE_FONT = { "3" => "3", "3+" => "3", "4" => "4A", "4+" => "4C", "5" => "5A", "5+" => "5C" }.freeze

  # French low grades are often written without a letter.
  BARE_FRENCH = { "1" => "1", "2" => "2", "3" => "3", "3+" => "3", "4" => "4a", "4+" => "4c",
                  "5" => "5a", "5+" => "5c" }.freeze

  BRITISH = /\A(HVD|HVS|MVS|VD|VS|HS|MS|E\d{1,2}|M|D|S)(\s|\z)/i

  module_function

  # Boulder, sport or trad. The logbook's gear style decides when it has one.
  # Otherwise V grades, an f prefix or an upper-case Font letter mean a
  # boulder, a British adjectival grade means trad, and anything else sport.
  def discipline(grade, gear_style: nil)
    style = gear_style.to_s.to_sym
    return style if SCALES.key?(style)

    text = grade.to_s.strip
    if text.match?(/\A(V\s*(\d|B)|f\s*\d|font|fb)/i) || text.match?(/\A\d[ABC]/)
      :boulder
    elsif text.match?(BRITISH)
      :trad
    else
      :sport
    end
  end

  def normalize(grade, discipline:)
    text = grade.to_s.strip
    return if text.empty?

    discipline == :boulder ? boulder(text) : route(text)
  end

  def boulder(text)
    if (v = text.match(/\AV\s*(B|\d{1,2})/i))
      return V_TO_FONT[v[1].upcase]
    end

    font = text.sub(/\A(font|fb|f)\s*/i, "").match(/\A([3-9])([abc])?(\+)?/i) or return
    return BARE_FONT["#{font[1]}#{font[3]}"] unless font[2]

    label = "#{font[1]}#{font[2].upcase}#{font[3]}"
    # Below 6A there are no plus grades on the scale: 5A+ counts as 5A.
    FONT.include?(label) ? label : "#{font[1]}#{font[2].upcase}".presence_in(FONT)
  end

  def route(text)
    if (yds = text.match(/\A5\.(\d{1,2})([abcd])?([+-])?/i))
      letter = yds[2]&.downcase || { "+" => "c", "-" => "a" }.fetch(yds[3], "a")
      key = yds[1].to_i >= 10 ? "5.#{yds[1]}#{letter}" : "5.#{yds[1]}"
      return YDS_TO_FRENCH[key]
    end

    if (british = text.match(BRITISH))
      return BRITISH_TO_FRENCH[british[1].upcase]
    end

    if (roman = text.match(/\A(XII|XI|X|IX|VIII|VII|VI|IV|V|III|II|I)([+-])?(\z|\s|\/)/))
      return UIAA_TO_FRENCH["#{ROMAN[roman[1]]}#{roman[2]}"]
    end

    sport = text.sub(/\Af\s*/i, "")
    if (french = sport.match(/\A([4-9])([abc])(\+)?/))
      label = "#{french[1]}#{french[2]}#{french[3]}"
      return label if FRENCH.include?(label)
    end

    if (number = sport.match(/\A(\d{1,2})([+-])?(\z|\s|\/)/))
      value = number[1].to_i
      return BARE_FRENCH["#{value}#{number[2]}"] if value <= 5
      return UIAA_TO_FRENCH["#{value}#{number[2]}"] if value <= 11
      return EWBANK_TO_FRENCH[value]
    end

    nil
  end
end
