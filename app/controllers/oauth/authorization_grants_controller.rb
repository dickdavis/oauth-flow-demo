# frozen_string_literal: true

module OAuth
  ##
  # Controller for granting authorization to clients
  class AuthorizationGrantsController < BaseController
    before_action :authenticate_user
    before_action :set_decoded_state
    before_action -> { load_oauth_client(id: @decoded_state[:client_id]) }

    def new
      state = params[:state]
      client_name = @oauth_client.name
      render :new, locals: { state:, client_name: }
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def create
      client_state = @decoded_state[:client_state]

      raise OAuth::AccessDenied unless ActiveModel::Type::Boolean.new.cast(params[:approve])

      grant = nil
      challenge = nil

      ActiveRecord::Base.transaction do
        grant = OAuth::AuthorizationGrant.new(oauth_client: @oauth_client, user: current_user)

        if @oauth_client.public_client_type?
          challenge = OAuth::Challenge.new(
            code_challenge: @decoded_state[:code_challenge],
            code_challenge_method: @decoded_state[:code_challenge_method],
            client_redirection_uri: @decoded_state[:redirect_uri],
            oauth_authorization_grant: grant
          )
        end

        grant.save!
        challenge&.save!
      end

      redirect_to_client(params_for_redirect: { code: grant.id, state: client_state })
    rescue OAuth::AccessDenied
      redirect_to_client(params_for_redirect: { error: 'access_denied', state: client_state })
    rescue ActiveRecord::RecordInvalid
      redirect_to_client(params_for_redirect: { error: 'invalid_request', state: client_state })
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    def set_decoded_state
      @decoded_state = JsonWebToken.decode(params[:state])
    end

    def redirect_to_client(params_for_redirect:)
      url = @oauth_client.url_for_redirect(params: params_for_redirect.compact)
      redirect_to url, allow_other_host: true
    end
  end
end
