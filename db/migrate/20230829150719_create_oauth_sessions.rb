# frozen_string_literal: true

##
# Creates oauth_sessions table.
class CreateOAuthSessions < ActiveRecord::Migration[7.0]
  def change
    create_enum :oauth_session_status, %w[created expired refreshed revoked]
    create_table :oauth_sessions, id: :uuid do |table|
      table.string :access_token_jti, null: false
      table.string :refresh_token_jti, null: false
      table.enum :status, enum_type: :oauth_session_status, default: 'created', null: false
      table.belongs_to :authorization_grant, null: false, type: :uuid, foreign_key: true, index: true

      table.timestamps
    end
    add_index :oauth_sessions, :access_token_jti, unique: true
    add_index :oauth_sessions, :refresh_token_jti, unique: true
  end
end
