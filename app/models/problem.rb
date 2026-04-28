class Problem < ApplicationRecord
  include Discard::Model

  belongs_to :board_layout
  belongs_to :created_by, class_name: "User", optional: true
  has_many :board_climbs, dependent: :destroy
  has_many :holds, -> { order(:kind, :position) }, dependent: :destroy

  validates :name, presence: true
  validates :grade, presence: true
  validate :at_least_one_hold
  validate :grade_in_grading_system

  # Filtering scopes
  scope :sent_or_flashed_by, ->(user) {
    where(id: BoardClimb.for_user(user).successful.select(:problem_id))
  }
  scope :not_sent_by, ->(user) {
    where.not(id: BoardClimb.for_user(user).successful.select(:problem_id))
  }

  # Sorting scopes
  scope :by_date, -> { order(created_at: :desc) }

  def self.by_grade(direction = :asc)
    sorted = all.sort_by { |p|
      gs = p.grading_system
      if gs
        gs.grades.index(p.grade) || 999
      else
        %w[VB V0 V1 V2 V3 V4 V5 V6 V7 V8 V9 V10 V11 V12 V13 V14 V15 V16 V17].index(p.grade) || 999
      end
    }
    direction == :desc ? sorted.reverse : sorted
  end

  def grading_system
    board_layout.board.grading_system
  end

  Hold::KINDS.each do |kind|
    define_method("#{kind}_holds") do
      if @pending_holds
        @pending_holds[kind].each_with_index.map { |h, i| { "x" => h[:x], "y" => h[:y], "id" => "p#{kind[0]}#{i}" } }
      else
        holds_by_kind[kind].map(&:to_marker)
      end
    end

    define_method("#{kind}_holds=") do |value|
      @pending_holds ||= Hold::KINDS.index_with { |k| holds_by_kind[k].map { |h| { x: h.x, y: h.y } } }
      @pending_holds[kind] = normalize_holds(value)
    end
  end

  after_save :persist_pending_holds

  def circuit_chart_data(user)
    board_climbs
      .circuit
      .for_user(user)
      .where.not(number_of_moves: nil)
      .order(:climbed_at)
      .pluck(:climbed_at, :number_of_moves)
      .map { |date, moves| [ date.to_date.to_s, moves ] }
  end

  private

  def holds_by_kind
    @holds_by_kind ||= Hold::KINDS.index_with { |kind| holds.select { |h| h.kind == kind }.sort_by(&:position) }
  end

  def normalize_holds(value)
    array = value.is_a?(String) ? (JSON.parse(value) rescue []) : Array(value)
    array.filter_map do |h|
      next unless h.is_a?(Hash)
      x = h["x"] || h[:x]
      y = h["y"] || h[:y]
      next if x.nil? || y.nil?
      { x: x.to_f, y: y.to_f }
    end
  end

  def persist_pending_holds
    return unless @pending_holds

    holds.destroy_all
    @pending_holds.each do |kind, array|
      array.each_with_index do |h, position|
        holds.create!(kind: kind, x: h[:x], y: h[:y], position: position)
      end
    end
    @pending_holds = nil
    @holds_by_kind = nil
  end

  def at_least_one_hold
    pending_empty = @pending_holds && @pending_holds.values.all?(&:empty?)
    persisted_empty = holds.empty? && @pending_holds.nil?
    if pending_empty || persisted_empty
      errors.add(:base, "Problem must have at least one hold of any type")
    end
  end

  def grade_in_grading_system
    gs = board_layout&.board&.grading_system
    return if gs.nil? || grade.blank?

    unless gs.grades.include?(grade)
      errors.add(:grade, "must be one of the valid grades in #{gs.name}: #{gs.grades.join(', ')}")
    end
  end
end

# == Schema Information
#
# Table name: problems
#
#  id              :integer          not null, primary key
#  circuit         :boolean          default(FALSE), not null
#  discarded_at    :datetime
#  grade           :string
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  board_layout_id :bigint           not null
#  created_by_id   :integer
#
# Indexes
#
#  index_problems_on_board_layout_id  (board_layout_id)
#  index_problems_on_created_by_id    (created_by_id)
#  index_problems_on_discarded_at     (discarded_at)
#
# Foreign Keys
#
#  board_layout_id  (board_layout_id => board_layouts.id)
#  created_by_id    (created_by_id => users.id)
#
