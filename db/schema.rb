# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151220014216) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "event_logs", force: :cascade do |t|
    t.string   "event_type"
    t.integer  "winning_team_id"
    t.integer  "losing_team_id"
    t.integer  "winning_team_score"
    t.integer  "losing_team_score"
    t.boolean  "acknowledged",       default: false
    t.integer  "user_id"
    t.integer  "match_id"
    t.integer  "match_map_id"
    t.integer  "server_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "host_machines", force: :cascade do |t|
    t.string   "address",      limit: 255, default: "localhost"
    t.integer  "port",                     default: 22
    t.string   "working_path", limit: 255, default: "/home/steam/"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "state",        limit: 255
    t.string   "user",         limit: 255, default: "steam"
    t.string   "password",     limit: 255, default: "5t3am"
    t.string   "region",                   default: "dal"
    t.string   "key_path"
  end

  create_table "match_maps", force: :cascade do |t|
    t.integer  "match_id"
    t.string   "map"
    t.string   "logs"
    t.string   "score"
    t.integer  "part_of_set", default: 0
    t.string   "state"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "matches", force: :cascade do |t|
    t.string   "state",             limit: 255
    t.string   "match_code",        limit: 255
    t.datetime "starts_at"
    t.string   "match_type",        limit: 255, default: "single"
    t.string   "region",            limit: 255, default: "dal"
    t.string   "score",             limit: 255
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.string   "match_format_name",             default: "evl_ultiduo"
    t.string   "tournament_id"
    t.string   "toorney_id"
  end

  create_table "matches_teams", id: false, force: :cascade do |t|
    t.integer "team_id"
    t.integer "match_id"
  end

  add_index "matches_teams", ["match_id"], name: "index_matches_teams_on_match_id", using: :btree
  add_index "matches_teams", ["team_id"], name: "index_matches_teams_on_team_id", using: :btree

  create_table "players", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "addresses",  limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "team_id"
    t.integer  "steam_id",   limit: 8
  end

  create_table "server_images", force: :cascade do |t|
    t.string   "game",            limit: 255, default: "tf"
    t.integer  "appid",                       default: 232250
    t.string   "path",            limit: 255, default: "tf2/"
    t.integer  "host_machine_id"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "config_source",   limit: 255, default: "tf2"
    t.string   "state",           limit: 255
  end

  create_table "servers", force: :cascade do |t|
    t.integer  "match_id"
    t.string   "hostname",        limit: 255
    t.string   "address",         limit: 255
    t.integer  "listen_port",                 default: 27015
    t.integer  "game_port",                   default: 27005
    t.integer  "stv_port",                    default: 27020
    t.string   "rcon_password",   limit: 255, default: "fuckyoubic"
    t.string   "sv_password",     limit: 255, default: "joinme"
    t.boolean  "managed",                     default: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "state",           limit: 255
    t.string   "map",             limit: 255
    t.integer  "num_players",                 default: 0
    t.integer  "server_image_id"
    t.integer  "metric",                      default: 100
    t.string   "region",                      default: "dal"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "tag",           limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "tournament_id"
    t.string   "toorney_id"
  end

  create_table "tournaments", id: false, force: :cascade do |t|
    t.string   "id",         null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "tournaments", ["id"], name: "index_tournaments_on_id", unique: true, using: :btree

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      limit: 255, null: false
    t.integer  "item_id",                    null: false
    t.string   "event",          limit: 255, null: false
    t.string   "whodunnit",      limit: 255
    t.text     "object"
    t.datetime "created_at"
    t.integer  "transaction_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree

end
