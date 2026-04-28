# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_28_213130) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "loggable_id", null: false
    t.string "loggable_type", null: false
    t.datetime "performed_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_activity_logs_on_loggable"
    t.index ["loggable_type", "user_id"], name: "index_activity_logs_on_loggable_type_and_user_id"
    t.index ["user_id", "performed_at"], name: "index_activity_logs_on_user_id_and_performed_at"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "board_climbs", force: :cascade do |t|
    t.integer "attempts", default: 1, null: false
    t.string "climb_type", null: false
    t.datetime "climbed_at", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.integer "number_of_moves"
    t.integer "problem_id", null: false
    t.datetime "updated_at", null: false
    t.index ["problem_id", "climbed_at"], name: "index_board_climbs_on_problem_id_and_climbed_at"
    t.index ["problem_id"], name: "index_board_climbs_on_problem_id"
  end

  create_table "board_layouts", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "archived_at"
    t.bigint "board_id", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["board_id", "active"], name: "index_board_layouts_on_board_id_and_active_unique", unique: true, where: "active = true AND discarded_at IS NULL"
    t.index ["board_id"], name: "index_board_layouts_on_board_id"
    t.index ["discarded_at"], name: "index_board_layouts_on_discarded_at"
  end

  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.integer "grading_system_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_boards_on_discarded_at"
    t.index ["grading_system_id"], name: "index_boards_on_grading_system_id"
  end

  create_table "crag_ascents", force: :cascade do |t|
    t.datetime "ascent_date", null: false
    t.string "ascent_type"
    t.text "comment"
    t.string "country"
    t.string "crag_name"
    t.string "crag_path"
    t.datetime "created_at", null: false
    t.string "gear_style"
    t.string "grade"
    t.string "partners"
    t.integer "quality"
    t.integer "route_height"
    t.string "route_name", null: false
    t.string "source"
    t.string "thecrag_ascent_id"
    t.datetime "updated_at", null: false
    t.index ["thecrag_ascent_id"], name: "index_crag_ascents_on_thecrag_ascent_id", unique: true, where: "thecrag_ascent_id IS NOT NULL"
  end

  create_table "exercise_types", force: :cascade do |t|
    t.boolean "added_weight_possible", default: false, null: false
    t.string "category", default: "other", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "reps"
    t.integer "rest_seconds"
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_exercise_types_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_exercise_types_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.decimal "added_weight"
    t.datetime "created_at", null: false
    t.integer "exercise_type_id", null: false
    t.text "notes"
    t.integer "reps"
    t.decimal "rpe"
    t.datetime "updated_at", null: false
    t.decimal "value"
    t.index ["exercise_type_id"], name: "index_exercises_on_exercise_type_id"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "followed_id", null: false
    t.integer "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "grading_systems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "grades", null: false
    t.string "name", null: false
    t.string "system_type", default: "custom", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["system_type"], name: "index_grading_systems_on_system_type"
    t.index ["user_id", "name"], name: "index_grading_systems_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_grading_systems_on_user_id"
  end

  create_table "gym_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.text "notes"
    t.integer "number_of_boulders"
    t.integer "number_of_circuits"
    t.integer "number_of_routes"
    t.datetime "updated_at", null: false
  end

  create_table "hikes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "distance_km", precision: 6, scale: 2
    t.decimal "duration_hours", precision: 4, scale: 2
    t.integer "elevation_gain_m"
    t.string "name", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
  end

  create_table "holds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.integer "position", default: 0, null: false
    t.integer "problem_id", null: false
    t.datetime "updated_at", null: false
    t.float "x", null: false
    t.float "y", null: false
    t.index ["problem_id", "kind", "position"], name: "index_holds_on_problem_id_and_kind_and_position"
    t.index ["problem_id"], name: "index_holds_on_problem_id"
  end

  create_table "measurements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "metric_id", null: false
    t.text "notes"
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", null: false
    t.index ["metric_id", "recorded_at"], name: "index_measurements_on_metric_id_and_recorded_at"
    t.index ["metric_id"], name: "index_measurements_on_metric_id"
  end

  create_table "metrics", force: :cascade do |t|
    t.string "category", default: "other", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_metrics_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_metrics_on_user_id"
  end

  create_table "problems", force: :cascade do |t|
    t.bigint "board_layout_id", null: false
    t.boolean "circuit", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.datetime "discarded_at"
    t.string "grade"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["board_layout_id"], name: "index_problems_on_board_layout_id"
    t.index ["created_by_id"], name: "index_problems_on_created_by_id"
    t.index ["discarded_at"], name: "index_problems_on_discarded_at"
  end

  create_table "system_board_climbs", force: :cascade do |t|
    t.integer "angle"
    t.integer "attempts"
    t.string "board", null: false
    t.string "climb_name", null: false
    t.string "climb_uuid"
    t.datetime "climbed_at", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.string "displayed_grade"
    t.boolean "is_benchmark", default: false
    t.boolean "is_mirror", default: false
    t.boolean "is_send", default: true, null: false
    t.integer "quality"
    t.string "setter_username"
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["uuid"], name: "index_system_board_climbs_on_uuid", unique: true
  end

  create_table "targets", force: :cascade do |t|
    t.datetime "applicable_from", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.integer "targetable_id", null: false
    t.string "targetable_type", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", null: false
    t.index ["targetable_type", "targetable_id", "applicable_from"], name: "index_targets_on_targetable_and_applicable_from"
    t.index ["targetable_type", "targetable_id"], name: "index_targets_on_targetable_type_and_targetable_id"
  end

  create_table "user_boards", force: :cascade do |t|
    t.bigint "board_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["board_id"], name: "index_user_boards_on_board_id"
    t.index ["user_id"], name: "index_user_boards_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "allow_follows", default: false, null: false
    t.string "boardsesh_email"
    t.datetime "boardsesh_last_synced_at"
    t.string "boardsesh_session_token"
    t.string "boardsesh_user_id"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.integer "default_grading_system_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "thecrag_synced_at"
    t.string "thecrag_username"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["default_grading_system_id"], name: "index_users_on_default_grading_system_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "board_climbs", "problems"
  add_foreign_key "board_layouts", "boards"
  add_foreign_key "boards", "grading_systems"
  add_foreign_key "exercise_types", "users"
  add_foreign_key "exercises", "exercise_types"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "grading_systems", "users"
  add_foreign_key "holds", "problems"
  add_foreign_key "measurements", "metrics"
  add_foreign_key "metrics", "users"
  add_foreign_key "problems", "board_layouts"
  add_foreign_key "problems", "users", column: "created_by_id"
  add_foreign_key "user_boards", "boards"
  add_foreign_key "user_boards", "users"
  add_foreign_key "users", "grading_systems", column: "default_grading_system_id"
end
