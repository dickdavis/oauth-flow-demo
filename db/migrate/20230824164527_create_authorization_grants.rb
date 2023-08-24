# frozen_string_literal: true

##
# Creates the authorization_grants table.
class CreateAuthorizationGrants < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_grants, id: :uuid do |table|
      table.string :code_challenge, null: false
      table.string :code_challenge_method, null: false, default: 'S256'
      table.datetime :expires_at, null: false
      table.string :client_id, null: false
      table.string :client_redirection_uri, null: false
      table.references :user

      table.timestamps
    end
  end
end
