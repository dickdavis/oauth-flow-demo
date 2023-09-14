# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'uri'

code_verifier = SecureRandom.base64(55).tr('+/', '-_').tr('=', '')
code_challenge = Digest::SHA256.base64digest(code_verifier).tr('+/', '-_').tr('=', '')
client_id = 'democlient'
client_secret = Rails.application.credentials.clients[client_id.to_sym]

puts <<~TEXT
  Copy down the code verifier and code challenge for referencing later in the process.

  code verifier: #{code_verifier}
  code challenge: #{code_challenge}

  Enter the URL into your browser, enter the client id and secret when prompted, and then enter login credentials for the resource owner.
  NOTE: An actual client would send the client id and secret via HTTP Basic authentication in the headers.

  http://localhost:3000/oauth/authorize?&client_id=#{client_id}&response_type=code&code_challenge=#{code_challenge}&code_challenge_method=S256

  The client used by this test script has the following credentials:
  client_id: #{client_id}
  client_secret: #{client_secret}

TEXT

puts 'Authorization code? -> '
authorization_code = gets.chomp

uri = URI.parse('http://localhost:3000/oauth/token')
request = Net::HTTP::Post.new(uri)
request.basic_auth(client_id, client_secret)
request.set_form_data(
  'code' => authorization_code,
  'code_verifier' => code_verifier,
  'grant_type' => 'authorization_code'
)

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

parsed_response = JSON.parse(response.body)

puts <<~TEXT

  Access token:
  #{parsed_response['access_token']}

  Refresh token:
  #{parsed_response['refresh_token']}

  Token type: #{parsed_response['token_type']}
  Expires in: #{parsed_response['expires_in']}

  #{response.body}
TEXT
