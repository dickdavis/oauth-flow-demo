# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'oauth/client_error' do
  before do
    render template: 'oauth/client_error', locals: { error_class: 'foo', error_message: 'bar' }
  end

  it 'renders the title' do
    expect(rendered).to match(/#{I18n.t('oauth.client_error.title')}/)
  end

  it 'renders the lede' do
    expect(rendered).to match(/#{I18n.t('oauth.client_error.lede')}/)
  end

  it 'renders the error class' do
    expect(rendered).to match(/foo/)
  end

  it 'renders the error message' do
    expect(rendered).to match(/bar/)
  end
end
