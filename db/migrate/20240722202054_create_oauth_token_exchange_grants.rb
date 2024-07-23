# frozen_string_literal: true

##
#  Creates the oauth_token_exchange_grants table
class CreateOAuthTokenExchangeGrants < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_token_exchange_grants, id: :uuid do |table|
      table.references :user, null: false, foreign_key: true
      table.belongs_to :oauth_client, null: false, type: :uuid, foreign_key: true, index: true

      table.timestamps
    end
  end
end
