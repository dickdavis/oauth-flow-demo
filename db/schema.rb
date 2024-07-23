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

ActiveRecord::Schema[7.0].define(version: 2024_07_22_202054) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "oauth_client_type", ["confidential", "public"]
  create_enum "oauth_session_status", ["created", "expired", "refreshed", "revoked"]

  create_table "oauth_authorization_grants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "expires_at", null: false
    t.boolean "redeemed", default: false, null: false
    t.uuid "oauth_client_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oauth_client_id"], name: "index_oauth_authorization_grants_on_oauth_client_id"
    t.index ["user_id"], name: "index_oauth_authorization_grants_on_user_id"
  end

  create_table "oauth_challenges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.string "redirect_uri"
    t.uuid "oauth_authorization_grant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oauth_authorization_grant_id"], name: "index_oauth_challenges_on_oauth_authorization_grant_id"
  end

  create_table "oauth_clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "api_key"
    t.string "name", null: false
    t.enum "client_type", default: "confidential", null: false, enum_type: "oauth_client_type"
    t.string "redirect_uri", null: false
    t.bigint "access_token_duration", default: 300, null: false
    t.bigint "refresh_token_duration", default: 1209600, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "oauth_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "access_token_jti", null: false
    t.string "refresh_token_jti", null: false
    t.enum "status", default: "created", null: false, enum_type: "oauth_session_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "oauth_authorization_grant_id"
    t.index ["access_token_jti"], name: "index_oauth_sessions_on_access_token_jti", unique: true
    t.index ["oauth_authorization_grant_id"], name: "index_oauth_sessions_on_oauth_authorization_grant_id"
    t.index ["refresh_token_jti"], name: "index_oauth_sessions_on_refresh_token_jti", unique: true
  end

  create_table "oauth_token_exchange_grants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.uuid "oauth_client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oauth_client_id"], name: "index_oauth_token_exchange_grants_on_oauth_client_id"
    t.index ["user_id"], name: "index_oauth_token_exchange_grants_on_user_id"
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

  add_foreign_key "oauth_authorization_grants", "oauth_clients"
  add_foreign_key "oauth_challenges", "oauth_authorization_grants"
  add_foreign_key "oauth_sessions", "oauth_authorization_grants"
  add_foreign_key "oauth_token_exchange_grants", "oauth_clients"
  add_foreign_key "oauth_token_exchange_grants", "users"
end
