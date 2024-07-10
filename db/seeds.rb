# frozen_string_literal: true

client = OAuth::Client.find_or_initialize_by(name: 'Sample Client') do |c|
  c.redirect_uri = 'http://localhost:3000/'
end
client.save if client.new_record?
