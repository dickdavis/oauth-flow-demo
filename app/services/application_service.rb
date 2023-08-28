# frozen_string_literal: true

##
# Base application service class
class ApplicationService
  def self.call(...)
    new(...).call
  end

  def self.call!(...)
    new(...).call!
  end
end
