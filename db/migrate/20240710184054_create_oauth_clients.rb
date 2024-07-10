# frozen_string_literal: true

##
# Creates `oauth_clients` table
class CreateOAuthClients < ActiveRecord::Migration[7.0]
  def change
    create_enum :oauth_client_type, %i[confidential public]
    create_table :oauth_clients, id: :uuid do |table|
      table.string :api_key
      table.string :name, null: false
      table.enum :client_type, enum_type: :oauth_client_type, null: false, default: 'confidential'
      table.string :redirect_uri, null: false
      # default to 5 minutes (in seconds)
      table.bigint :access_token_duration, null: false,  default: 300
      # default to 14 days (in seconds)
      table.bigint :refresh_token_duration, null: false, default: 1_209_600

      table.timestamps
    end
  end
end
