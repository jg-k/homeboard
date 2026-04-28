require "prawn"
require "vips"

Prawn::Fonts::AFM.hide_m17n_warning = true

class BoardExport
  HOLD_COLORS = {
    "start" => "FF9500",
    "finish" => "16A34A",
    "hand" => "DC2626",
    "foot" => "FFFF00"
  }.freeze

  SPOTLIGHT_DARKNESS = 0.55
  SPOTLIGHT_RADIUS_RATIO = 0.028
  BEZIER_K = 0.5522847498307936

  def initialize(board, user = nil)
    @board = board
    @user = user
  end

  def to_pdf
    pdf = Prawn::Document.new(page_size: "A4", margin: 36)
    problems = @board.problems.kept.includes(:holds, board_layout: { image_layout_attachment: :blob }).by_grade
    @sent_at_by_problem = load_sent_dates(problems)

    render_cover(pdf, problems)
    problems.each do |problem|
      pdf.start_new_page
      render_problem(pdf, problem)
    end

    pdf.render
  ensure
    @tempfiles&.each(&:close!)
  end

  private

  def load_sent_dates(problems)
    return {} unless @user

    BoardClimb.for_user(@user).successful
      .where(problem_id: problems.map(&:id))
      .group(:problem_id).minimum(:climbed_at)
  end

  def render_cover(pdf, problems)
    pdf.font_size(24) { pdf.text @board.name, style: :bold }
    pdf.move_down 6
    pdf.font_size(10) { pdf.text "Exported #{Date.current.strftime('%B %d, %Y')} · #{problems.size} problems", color: "666666" }
    pdf.move_down 18

    pdf.font_size(10) do
      problems.each_with_index do |problem, i|
        pdf.text "#{i + 2}. #{problem.name} — #{problem.grade}"
      end
    end
  end

  def render_problem(pdf, problem)
    pdf.font_size(16) { pdf.text problem.name, style: :bold }
    subheader = [ problem.grade, problem.board_layout.name, "##{problem.id}" ]
    if (sent_at = @sent_at_by_problem[problem.id])
      subheader << "sent #{sent_at.to_date.strftime('%b %-d, %Y')}"
    end
    pdf.font_size(11) { pdf.text subheader.join(" · "), color: "666666" }
    pdf.move_down 10

    render_layout_with_holds(pdf, problem)
  end

  def render_layout_with_holds(pdf, problem)
    path = layout_image_path(problem.board_layout)
    return pdf.text("(no layout image)", color: "999999") unless path

    spotlight_path = spotlight_image_path(path, problem)

    max_width = pdf.bounds.width
    max_height = pdf.bounds.height - pdf.cursor - 80

    image_info = pdf.image(spotlight_path, fit: [ max_width, max_height ], position: :center)
    draw_holds(pdf, problem, image_info)
  end

  def draw_holds(pdf, problem, image_info)
    iw = image_info.scaled_width
    ih = image_info.scaled_height
    ix = pdf.bounds.left + (pdf.bounds.width - iw) / 2.0
    iy_top = pdf.cursor + ih
    radius = [ iw * SPOTLIGHT_RADIUS_RATIO, 6 ].max

    problem.holds.each do |hold|
      cx = ix + (hold.x / 100.0) * iw
      cy = iy_top - (hold.y / 100.0) * ih
      draw_hold_marker(pdf, hold.kind, cx, cy, radius)
    end
  end

  def draw_hold_marker(pdf, kind, cx, cy, radius)
    pdf.stroke_color HOLD_COLORS.fetch(kind, "000000")
    pdf.line_width [ radius * 0.12, 1.5 ].max
    if kind == "hand" || kind == "foot"
      stroke_bottom_half_circle(pdf, cx, cy, radius)
    else
      pdf.stroke_circle [ cx, cy ], radius
    end
  ensure
    pdf.stroke_color "000000"
    pdf.line_width 1
  end

  def stroke_bottom_half_circle(pdf, cx, cy, r)
    k = BEZIER_K
    pdf.move_to [ cx - r, cy ]
    pdf.curve_to [ cx, cy - r ], bounds: [ [ cx - r, cy - k * r ], [ cx - k * r, cy - r ] ]
    pdf.curve_to [ cx + r, cy ], bounds: [ [ cx + k * r, cy - r ], [ cx + r, cy - k * r ] ]
    pdf.stroke
  end

  def layout_image_path(board_layout)
    return nil unless board_layout.image_layout.attached?

    variant = board_layout.image_layout.variant(resize_to_limit: [ 1200, 1200 ], saver: { quality: 70 }).processed
    tempfile = Tempfile.new([ "board_layout_#{board_layout.id}_", ".jpg" ])
    tempfile.binmode
    tempfile.write(variant.download)
    tempfile.rewind

    (@tempfiles ||= []) << tempfile
    tempfile.path
  rescue ActiveStorage::FileNotFoundError
    nil
  end

  def spotlight_image_path(source_path, problem)
    return source_path if problem.holds.empty?

    image = Vips::Image.new_from_file(source_path)
    image = image.extract_band(0, n: 3) if image.bands > 3
    w = image.width
    h = image.height

    dark = (image * SPOTLIGHT_DARKNESS).cast("uchar")
    radius = (w * SPOTLIGHT_RADIUS_RATIO).round

    mask = Vips::Image.black(w, h).cast("uchar")
    problem.holds.each do |hold|
      cx = (hold.x / 100.0 * w).round
      cy = (hold.y / 100.0 * h).round
      mask = mask.draw_circle(255, cx, cy, radius, fill: true)
    end

    result = mask.ifthenelse(image, dark)

    output = Tempfile.new([ "spotlight_#{problem.id}_", ".jpg" ])
    output.binmode
    result.jpegsave(output.path, Q: 65, optimize_coding: true, interlace: true, strip: true)
    (@tempfiles ||= []) << output
    output.path
  end
end
