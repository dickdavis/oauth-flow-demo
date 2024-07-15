# frozen_string_literal: true

require 'digest'

client = OAuth::Client.where(client_type: 'confidential').first
client_id = client.id
client_secret = client.api_key

puts <<~TEXT
  Copy down the code verifier and code challenge for referencing later in the process when using Postman to send requests.

  Enter the URL into your browser, enter the client id and secret when prompted, and then enter login credentials for the resource owner.
  NOTE: An actual client would send the client id and secret via HTTP Basic authentication in the headers.

  http://localhost:3000/oauth/authorize?&response_type=code

  The client used by this test script has the following credentials:
  client_id: #{client_id}
  client_secret: #{client_secret}
TEXT
