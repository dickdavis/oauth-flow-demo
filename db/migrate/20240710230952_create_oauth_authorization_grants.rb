# frozen_string_literal: true

##
# Creates the oauth_authorization_grants table.
class CreateOAuthAuthorizationGrants < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/MethodLength
  def up
    create_table :oauth_authorization_grants, id: :uuid do |table|
      table.datetime :expires_at, null: false
      table.boolean :redeemed, null: false, default: false
      table.belongs_to :oauth_client, null: false, type: :uuid, foreign_key: true, index: true
      table.references :user

      table.timestamps
    end

    create_table :oauth_challenges, id: :uuid do |table|
      table.string :code_challenge, null: true
      table.string :code_challenge_method, null: true
      table.string :redirect_uri, null: true
      table.belongs_to :oauth_authorization_grant, null: false, type: :uuid, foreign_key: true, index: true

      table.timestamps
    end

    add_reference :oauth_sessions, :oauth_authorization_grant, foreign_key: true, type: :uuid
    remove_column :oauth_sessions, :authorization_grant_id

    drop_table :authorization_grants
  end

  def down
    create_table :authorization_grants do |table|
      table.string :code_challenge, null: false
      table.string :code_challenge_method, null: false, default: 'S256'
      table.datetime :expires_at, null: false
      table.string :client_id, null: false
      table.string :client_redirection_uri, null: false
      table.references :user

      table.timestamps
    end

    add_reference :oauth_sessions, :authorization_grant, foreign_key: true

    remove_reference :oauth_sessions, :oauth_authorization_grant

    drop_table :oauth_challenges
    drop_table :oauth_authorization_grants
  end
  # rubocop:enable Metrics/MethodLength
end
