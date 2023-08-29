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

ActiveRecord::Schema[7.0].define(version: 2023_08_29_150719) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "oauth_session_status", ["created", "expired", "refreshed", "revoked"]

  create_table "authorization_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code_challenge", null: false
    t.string "code_challenge_method", default: "S256", null: false
    t.datetime "expires_at", null: false
    t.string "client_id", null: false
    t.string "client_redirection_uri", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "redeemed", default: false, null: false
    t.index ["user_id"], name: "index_authorization_grants_on_user_id"
  end

  create_table "oauth_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token_jti", null: false
    t.string "refresh_token_jti", null: false
    t.enum "status", default: "created", null: false, enum_type: "oauth_session_status"
    t.uuid "authorization_grant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token_jti"], name: "index_oauth_sessions_on_access_token_jti", unique: true
    t.index ["authorization_grant_id"], name: "index_oauth_sessions_on_authorization_grant_id"
    t.index ["refresh_token_jti"], name: "index_oauth_sessions_on_refresh_token_jti", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "oauth_sessions", "authorization_grants"
end
