class UserBoard < ApplicationRecord
  belongs_to :user
  belongs_to :board
end

# == Schema Information
#
# Table name: user_boards
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  board_id   :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_boards_on_board_id  (board_id)
#  index_user_boards_on_user_id   (user_id)
#
# Foreign Keys
#
#  board_id  (board_id => boards.id)
#  user_id   (user_id => users.id)
#
