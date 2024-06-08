# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'oauth/client_error' do
  before do
    render template: 'oauth/client_error', locals: { error_class: 'foo', error_message: 'bar' }
  end

  it 'renders the title, lede, error class, and error message' do
    aggregate_failures do
      expect(rendered).to match(/#{I18n.t('oauth.client_error.title')}/)
      expect(rendered).to match(/#{I18n.t('oauth.client_error.lede')}/)
      expect(rendered).to match(/foo/)
      expect(rendered).to match(/bar/)
    end
  end
end
