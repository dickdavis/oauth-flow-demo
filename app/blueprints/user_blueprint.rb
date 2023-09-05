# frozen_string_literal: true

##
# Serializes user objects
class UserBlueprint < Blueprinter::Base
  fields :first_name, :last_name, :email
end
