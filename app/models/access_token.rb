# frozen_string_literal: true

##
# Models an access token
class AccessToken
  include ClaimValidatable

  attr_accessor :user_id

  validates :user_id, presence: true, comparison: { equal_to: :user_id_from_oauth_session }

  private

  def user_id_from_oauth_session
    oauth_session&.user_id
  end
end
