# frozen_string_literal: true

##
# Namespace for OAuth-related models
module OAuth
  CONFIG = Rails.configuration.oauth.freeze

  def self.table_name_prefix
    'oauth_'
  end

  ##
  # Error for when client_id param is missing.
  class MissingClientIdError < StandardError
    def initialize(msg = 'Request does not contain required parameter: client_id')
      super
    end
  end

  ##
  # Error for when the OAuth client is invalid.
  class InvalidClientError < StandardError; end

  ##
  # Error for when the OAuth client is mismatched.
  class ClientMismatchError < StandardError; end

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
  # Error for when OAuth Session is not found.
  class OAuthSessionNotFound < StandardError; end

  ##
  # Error for when client provides a code that does not map to an valid authorization grant.
  class InvalidGrantError < StandardError; end

  ##
  # Error for when the resource probided fails validation.
  class InvalidResourceError < StandardError; end

  ##
  # Error for when the subject token type fails validation.
  class InvalidSubjectTokenTypeError < StandardError; end

  ##
  # Error for when client provides a code verifier that fails validation.
  class InvalidCodeVerifierError < StandardError; end

  ##
  # Error for when an invalid redirection_uri is provided.
  class InvalidRedirectionURIError < StandardError; end

  ##
  # Error for when a PKCE challenge has failed.
  class UnsuccessfulChallengeError < StandardError; end

  ##
  # Error for when an authorization code has already beed redeemed.
  class AuthorizationCodeRedeemedError < StandardError; end

  ##
  # Error for when server experiences an error.
  class ServerError < StandardError; end

  ##
  # Error for when an authorization header is not provided.
  class MissingAuthorizationHeaderError < StandardError; end

  ##
  # Error for when an invalid access token is provided.
  class InvalidAccessTokenError < StandardError; end

  ##
  # Error for when an unauthorized access token is provided.
  class UnauthorizedAccessTokenError < StandardError; end

  ##
  # Error for when an OAuthSession is revoked.
  class RevokedSessionError < StandardError
    attr_reader :client_id, :refreshed_session_id, :revoked_session_id, :user_id

    def initialize(client_id:, refreshed_session_id:, revoked_session_id:, user_id:)
      super()
      @client_id = client_id
      @refreshed_session_id = refreshed_session_id
      @revoked_session_id = revoked_session_id
      @user_id = user_id
    end

    def message
      I18n.t('oauth.revoked_session_error', client_id:, refreshed_session_id:, revoked_session_id:, user_id:)
    end
  end
end
