class BoardLayout < ApplicationRecord
  include Discard::Model

  belongs_to :board
  has_many :problems, dependent: :destroy
  has_one_attached :image_layout

  # Max dimension for compressed layout images (change as needed)
  IMAGE_MAX_DIMENSION = 1280

  attr_accessor :use_sample_image

  def display_image
    return unless image_layout.attached?

    image_layout.variant(
      resize_to_limit: [ IMAGE_MAX_DIMENSION, IMAGE_MAX_DIMENSION ],
      saver: { quality: 85 }
    )
  end

  validates :name, presence: true
  validate :image_or_sample_required, on: :create

  before_create :activate_and_deactivate_others
  before_create :attach_sample_image_if_requested
  before_update :deactivate_other_layouts, if: :will_save_change_to_active?

  scope :active, -> { where(active: true) }
  scope :not_archived, -> { where(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def toggle_archive!
    update!(archived_at: archived? ? nil : Time.current)
    activate_next_if_needed!
  end

  def activate_next_if_needed!
    return unless active? && (archived? || discarded?)

    update_column(:active, false)
    next_layout = board.board_layouts.kept.not_archived.where.not(id: id).order(created_at: :desc).first
    next_layout&.update!(active: true)
  end

  def self.active_for_board(board)
    kept.where(board: board, active: true).first
  end

  private

  def activate_and_deactivate_others
    board.board_layouts.kept.where(active: true).update_all(active: false)
    self.active = true
  end

  def deactivate_other_layouts
    return unless active?

    # Deactivate all other layouts for this board
    board.board_layouts.kept.where.not(id: id).update_all(active: false)
  end

  def attach_sample_image_if_requested
    return unless use_sample_image == "1" && !image_layout.attached?

    sample_path = Rails.root.join("app/assets/images/hb.jpg")
    image_layout.attach(
      io: File.open(sample_path),
      filename: "sample_layout.jpg",
      content_type: "image/jpeg"
    )
  end

  def image_or_sample_required
    return if image_layout.attached? || use_sample_image == "1"

    errors.add(:base, "Please upload an image or use the sample image")
  end
end

# == Schema Information
#
# Table name: board_layouts
#
#  id           :integer          not null, primary key
#  active       :boolean          default(FALSE), not null
#  archived_at  :datetime
#  discarded_at :datetime
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  board_id     :bigint           not null
#
# Indexes
#
#  index_board_layouts_on_board_id                    (board_id)
#  index_board_layouts_on_board_id_and_active_unique  (board_id,active) UNIQUE WHERE active = true AND discarded_at IS NULL
#  index_board_layouts_on_discarded_at                (discarded_at)
#
# Foreign Keys
#
#  board_id  (board_id => boards.id)
#
