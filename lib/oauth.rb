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

  ##
  # Error for when resource owner denies access request.
  class AccessDenied < StandardError; end

  ##
  # Error for when client provides an unsupported grant type param.
  class UnsupportedGrantTypeError < StandardError; end

  ##
  # Error for when client provides a code that does not map to an valid authorization grant.
  class InvalidGrantError < StandardError; end

  ##
  # Error for when client provides a param that fails validation.
  class InvalidRequestError < StandardError; end
end
