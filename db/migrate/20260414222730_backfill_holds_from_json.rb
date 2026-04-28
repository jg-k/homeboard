class BackfillHoldsFromJson < ActiveRecord::Migration[8.1]
  KINDS = {
    "start_holds" => "start",
    "finish_holds" => "finish",
    "hand_holds" => "hand",
    "foot_holds" => "foot"
  }.freeze

  def up
    rows = execute("SELECT id, start_holds, finish_holds, hand_holds, foot_holds FROM problems").to_a
    now = Time.current

    inserts = []
    rows.each do |row|
      KINDS.each do |column, kind|
        raw = row[column]
        next if raw.blank?

        begin
          holds = JSON.parse(raw)
        rescue JSON::ParserError
          next
        end
        next unless holds.is_a?(Array)

        holds.each_with_index do |hold, position|
          next unless hold.is_a?(Hash) && hold["x"] && hold["y"]

          inserts << {
            problem_id: row["id"],
            kind: kind,
            x: hold["x"].to_f,
            y: hold["y"].to_f,
            position: position,
            created_at: now,
            updated_at: now
          }
        end
      end
    end

    return if inserts.empty?

    inserts.each_slice(500) do |batch|
      values = batch.map do |h|
        "(#{h[:problem_id]}, #{connection.quote(h[:kind])}, #{h[:x]}, #{h[:y]}, #{h[:position]}, #{connection.quote(h[:created_at])}, #{connection.quote(h[:updated_at])})"
      end.join(", ")
      execute("INSERT INTO holds (problem_id, kind, x, y, position, created_at, updated_at) VALUES #{values}")
    end
  end

  def down
    execute("DELETE FROM holds")
  end
end
