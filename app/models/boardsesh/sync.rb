class Boardsesh::Sync
  Result = Struct.new(:imported_count, :skipped_count, :errors, keyword_init: true)

  KILTER_GRADE_MAP = {
    10 => "4a/V0", 11 => "4b/V0", 12 => "4c/V0",
    13 => "5a/V1", 14 => "5b/V1",
    15 => "5c/V2",
    16 => "6a/V3", 17 => "6a+/V3",
    18 => "6b/V4", 19 => "6b+/V4",
    20 => "6c/V5", 21 => "6c+/V5",
    22 => "7a/V6",
    23 => "7a+/V7",
    24 => "7b/V8", 25 => "7b+/V8",
    26 => "7c/V9",
    27 => "7c+/V10",
    28 => "8a/V11",
    29 => "8a+/V12",
    30 => "8b/V13",
    31 => "8b+/V14",
    32 => "8c/V15",
    33 => "8c+/V16"
  }.freeze

  def initialize(user:)
    @user = user
  end

  def call
    unless @user.boardsesh_user_id.present?
      return Result.new(imported_count: 0, skipped_count: 0, errors: [ "Boardsesh account not connected" ])
    end

    client = Boardsesh::Client.new

    imported_count = 0
    skipped_count = 0
    errors = []

    begin
      ascents = client.fetch_all_ascents(@user.boardsesh_user_id, since: @user.boardsesh_last_synced_at)

      ActiveRecord::Base.transaction do
        ascents.each do |ascent|
          result = import_ascent(ascent)
          case result
          when :imported then imported_count += 1
          when :skipped then skipped_count += 1
          else errors << result
          end
        end

        @user.update!(boardsesh_last_synced_at: Time.current)
      end
    rescue Boardsesh::Client::ApiError => e
      errors << "API error: #{e.message}"
    end

    Result.new(imported_count: imported_count, skipped_count: skipped_count, errors: errors)
  end

  private

  def import_ascent(ascent)
    board_type = ascent["boardType"]
    climbed_at = parse_datetime(ascent["climbedAt"])
    uuid = build_uuid(board_type, ascent["climbUuid"], climbed_at)
    return :skipped if SystemBoardClimb.exists?(uuid: uuid)

    is_send = ascent["status"] == "flash" || ascent["status"] == "send"
    grade = ascent["difficultyName"].presence ||
            ascent["consensusDifficultyName"].presence ||
            difficulty_to_grade(ascent["difficulty"])

    board_climb = SystemBoardClimb.new(
      uuid: uuid,
      climb_uuid: ascent["climbUuid"],
      board: "boardsesh_#{board_type}",
      climb_name: ascent["climbName"].presence || "Unknown Climb",
      setter_username: ascent["setterUsername"],
      climbed_at: climbed_at,
      angle: ascent["angle"],
      attempts: ascent["attemptCount"],
      displayed_grade: grade,
      is_send: is_send,
      comment: nil
    )

    if board_climb.save
      board_climb.create_activity_log!(user: @user, performed_at: board_climb.climbed_at)
      :imported
    else
      "#{uuid}: #{board_climb.errors.full_messages.join(', ')}"
    end
  end

  def build_uuid(board_type, climb_uuid, climbed_at)
    "boardsesh-#{board_type}-#{climb_uuid}-#{climbed_at&.utc&.iso8601(3)}"
  end

  def difficulty_to_grade(difficulty)
    return nil if difficulty.nil?

    KILTER_GRADE_MAP[difficulty.round] || "V?"
  end

  def parse_datetime(value)
    return nil if value.blank?

    Time.find_zone("UTC").parse(value)
  rescue ArgumentError
    nil
  end
end
