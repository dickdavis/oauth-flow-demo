# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'uri'

code_verifier = SecureRandom.base64(55).tr('+/', '-_').tr('=', '')
code_challenge = Digest::SHA256.base64digest(code_verifier).tr('+/', '-_').tr('=', '')
client_id = 'democlient'

puts <<~TEXT
  Copy down the code verifier and code challenge for referencing later in the process.

  code verifier: #{code_verifier}
  code challenge: #{code_challenge}

  Enter the URL into your browser and then enter login credentials for the resource owner.

  http://localhost:3000/authorize?&client_id=#{client_id}&response_type=code&code_challenge=#{code_challenge}&code_challenge_method=S256
TEXT

# puts 'Authorization code? -> '
# authorization_code = gets.chomp
#
# uri = URI.parse('https://api.dropbox.com/oauth2/token')
# request = Net::HTTP::Post.new(uri)
# request.set_form_data(
#   'client_id' => app_key,
#   'code' => authorization_code,
#   'code_verifier' => code_verifier,
#   'grant_type' => 'authorization_code',
# )
#
# req_options = {
#   use_ssl: uri.scheme == 'https',
# }
#
# response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
#   http.request(request)
# end
#
# puts response.body
# puts "Access token: #{response.body['access_token']}"
