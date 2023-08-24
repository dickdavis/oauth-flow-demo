# frozen_string_literal: true

##
# Enables the pgcrypto extension for generating UUIDs as primary keys
class EnableUuid < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto'
  end
end
