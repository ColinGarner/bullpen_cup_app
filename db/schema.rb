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

ActiveRecord::Schema[8.0].define(version: 2025_07_20_215358) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "joined_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["joined_at"], name: "index_group_memberships_on_joined_at"
    t.index ["role"], name: "index_group_memberships_on_role"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.jsonb "settings", default: {}
    t.string "contact_email"
    t.string "contact_phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_code", limit: 8, null: false
    t.index ["active"], name: "index_groups_on_active"
    t.index ["invite_code"], name: "index_groups_on_invite_code", unique: true
    t.index ["name"], name: "index_groups_on_name"
    t.index ["slug"], name: "index_groups_on_slug", unique: true
  end

  create_table "match_players", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "team_id"], name: "index_match_players_on_match_id_and_team_id"
    t.index ["match_id", "user_id"], name: "index_match_players_on_match_and_user_unique", unique: true
    t.index ["match_id", "user_id"], name: "index_match_players_on_match_id_and_user_id"
    t.index ["match_id"], name: "index_match_players_on_match_id"
    t.index ["team_id", "user_id"], name: "index_match_players_on_team_id_and_user_id"
    t.index ["team_id"], name: "index_match_players_on_team_id"
    t.index ["user_id"], name: "index_match_players_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "round_id", null: false
    t.bigint "team_a_id", null: false
    t.bigint "team_b_id", null: false
    t.string "match_type", null: false
    t.string "status", default: "upcoming", null: false
    t.bigint "winner_team_id"
    t.datetime "scheduled_time"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "golf_course_id"
    t.string "golf_course_name"
    t.string "golf_course_location"
    t.bigint "scorer_user_id"
    t.jsonb "holes_data"
    t.string "selected_tee_name"
    t.index ["golf_course_id"], name: "index_matches_on_golf_course_id"
    t.index ["match_type"], name: "index_matches_on_match_type"
    t.index ["round_id", "status"], name: "index_matches_on_round_id_and_status"
    t.index ["round_id"], name: "index_matches_on_round_id"
    t.index ["status"], name: "index_matches_on_status"
    t.index ["team_a_id", "team_b_id"], name: "index_matches_on_team_a_id_and_team_b_id"
    t.index ["team_a_id"], name: "index_matches_on_team_a_id"
    t.index ["team_b_id"], name: "index_matches_on_team_b_id"
    t.index ["winner_team_id"], name: "index_matches_on_winner_team_id"
    t.check_constraint "team_a_id <> team_b_id", name: "matches_different_teams"
  end

  create_table "rounds", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.integer "round_number", null: false
    t.string "name", null: false
    t.date "date"
    t.string "status", default: "upcoming", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_rounds_on_status"
    t.index ["tournament_id", "date"], name: "index_rounds_on_tournament_id_and_date"
    t.index ["tournament_id", "round_number"], name: "index_rounds_on_tournament_id_and_round_number", unique: true
    t.index ["tournament_id"], name: "index_rounds_on_tournament_id"
  end

  create_table "scores", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "user_id", null: false
    t.integer "hole_number"
    t.integer "strokes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "net_strokes"
    t.decimal "handicap_used", precision: 4, scale: 1
    t.integer "strokes_received_on_hole", default: 0, null: false
    t.string "hole_result"
    t.index ["hole_result"], name: "index_scores_on_hole_result"
    t.index ["match_id", "hole_number"], name: "index_scores_on_match_and_hole"
    t.index ["match_id", "user_id", "hole_number"], name: "index_scores_unique_per_hole", unique: true
    t.index ["match_id"], name: "index_scores_on_match_id"
    t.index ["user_id", "handicap_used"], name: "index_scores_on_user_and_handicap"
    t.index ["user_id"], name: "index_scores_on_user_id"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.datetime "joined_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "tournament_id", null: false
    t.bigint "captain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["captain_id"], name: "index_teams_on_captain_id"
    t.index ["tournament_id", "name"], name: "index_teams_on_tournament_id_and_name", unique: true
    t.index ["tournament_id"], name: "index_teams_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "venue"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "cancelled", default: false, null: false
    t.bigint "group_id"
    t.index ["cancelled"], name: "index_tournaments_on_cancelled"
    t.index ["created_by_id"], name: "index_tournaments_on_created_by_id"
    t.index ["group_id"], name: "index_tournaments_on_group_id"
    t.index ["start_date"], name: "index_tournaments_on_start_date"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.string "first_name"
    t.string "last_name"
    t.decimal "handicap", precision: 4, scale: 1
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "match_players", "matches"
  add_foreign_key "match_players", "teams"
  add_foreign_key "match_players", "users"
  add_foreign_key "matches", "rounds"
  add_foreign_key "matches", "teams", column: "team_a_id"
  add_foreign_key "matches", "teams", column: "team_b_id"
  add_foreign_key "matches", "teams", column: "winner_team_id"
  add_foreign_key "rounds", "tournaments"
  add_foreign_key "scores", "matches"
  add_foreign_key "scores", "users"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "tournaments"
  add_foreign_key "teams", "users", column: "captain_id"
  add_foreign_key "tournaments", "groups"
  add_foreign_key "tournaments", "users", column: "created_by_id"
end
