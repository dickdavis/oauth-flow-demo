# frozen_string_literal: true

##
# Controller for granting authorization to clients
class AuthorizationGrantsController < ApplicationController
  before_action :authenticate_user

  def new
    state = params[:state]
    payload = JsonWebToken.decode(state)
    client_name = Rails.configuration.oauth.clients.dig(payload[:client_id].to_sym, :name)
    render 'authorization_grants/new', locals: { state:, client_name: }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    payload = JsonWebToken.decode(params[:state])
    client_id = payload[:client_id]
    client_state = payload[:client_state]

    raise OAuth::AccessDenied unless ActiveModel::Type::Boolean.new.cast(params[:approve])

    grant = AuthorizationGrant.new(
      code_challenge: payload[:code_challenge],
      code_challenge_method: payload[:code_challenge_method],
      client_id:,
      client_redirection_uri: Rails.configuration.oauth.clients.dig(client_id.to_sym, :redirection_uri),
      user: current_user
    )

    if grant.save
      redirect_to_client(client_id:, params_for_redirect: { code: grant.id, state: client_state })
    else
      redirect_to_client(client_id:, params_for_redirect: { error: 'invalid_request', state: client_state })
    end
  rescue OAuth::AccessDenied
    redirect_to_client(client_id:, params_for_redirect: { error: 'access_denied', state: client_state })
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

  def redirect_to_client(client_id:, params_for_redirect:)
    result = ClientRedirectUrlService.call(client_id:, params: params_for_redirect.compact)
    redirect_to result.url, allow_other_host: true
  end
end
