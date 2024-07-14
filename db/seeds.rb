# frozen_string_literal: true

confidential_client = OAuth::Client.find_or_initialize_by(name: 'Confidential Client') do |c|
  c.redirect_uri = 'http://localhost:3000/'
end
confidential_client.save if confidential_client.new_record?

public_client = OAuth::Client.find_or_initialize_by(name: 'Public Client') do |c|
  c.client_type = 'public'
  c.redirect_uri = 'http://localhost:3000/'
end
public_client.save if public_client.new_record?
