# frozen_string_literal: true

##
# Adds the redeemed column to authorization_grants to track when codes have been used.
class AddRedeemedToAuthorizationGrants < ActiveRecord::Migration[7.0]
  def change
    add_column :authorization_grants, :redeemed, :boolean, default: false, null: false
  end
end
