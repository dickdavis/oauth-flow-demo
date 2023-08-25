# frozen_string_literal: true

##
# Provides errors for OAuth server
module OAuth
  ##
  # Error for when client_id param is missing.
  class MissingClientIdError < StandardError
    def initialize(msg = 'Request does not contain required parameter: client_id')
      super
    end
  end

  ##
  # Error for when client redirection URI is invalid.
  class InvalidRedirectUrlError < StandardError; end
end
