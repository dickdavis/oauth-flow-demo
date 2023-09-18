# frozen_string_literal: true

require 'digest'

code_verifier = SecureRandom.base64(55).tr('+/', '-_').tr('=', '')
code_challenge = Digest::SHA256.base64digest(code_verifier).tr('+/', '-_').tr('=', '')
client_id = 'democlient'
client_secret = Rails.application.credentials.clients[client_id.to_sym]

puts <<~TEXT
  Copy down the code verifier and code challenge for referencing later in the process when using Postman to send requests.

  code verifier: #{code_verifier}
  code challenge: #{code_challenge}

  Enter the URL into your browser, enter the client id and secret when prompted, and then enter login credentials for the resource owner.
  NOTE: An actual client would send the client id and secret via HTTP Basic authentication in the headers.

  http://localhost:3000/oauth/authorize?&client_id=#{client_id}&response_type=code&code_challenge=#{code_challenge}&code_challenge_method=S256

  The client used by this test script has the following credentials:
  client_id: #{client_id}
  client_secret: #{client_secret}
TEXT
