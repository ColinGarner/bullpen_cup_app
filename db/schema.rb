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

ActiveRecord::Schema[8.0].define(version: 2025_07_18_131855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["cancelled"], name: "index_tournaments_on_cancelled"
    t.index ["created_by_id"], name: "index_tournaments_on_created_by_id"
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
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "match_players", "matches"
  add_foreign_key "match_players", "teams"
  add_foreign_key "match_players", "users"
  add_foreign_key "matches", "rounds"
  add_foreign_key "matches", "teams", column: "team_a_id"
  add_foreign_key "matches", "teams", column: "team_b_id"
  add_foreign_key "matches", "teams", column: "winner_team_id"
  add_foreign_key "rounds", "tournaments"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "tournaments"
  add_foreign_key "teams", "users", column: "captain_id"
  add_foreign_key "tournaments", "users", column: "created_by_id"
end
