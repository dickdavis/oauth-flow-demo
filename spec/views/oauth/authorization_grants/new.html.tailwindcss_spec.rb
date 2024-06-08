# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'oauth/authorization_grants/new' do
  before do
    render template: 'oauth/authorization_grants/new', locals: { state: 'foo', client_name: 'bar' }
  end

  it 'renders the title, lede, and client name' do
    aggregate_failures do
      expect(rendered).to match(/#{I18n.t('oauth.authorization_grants.new.title')}/)
      expect(rendered).to match(/#{I18n.t('oauth.authorization_grants.new.lede')}/)
      expect(rendered).to match(/bar/)
    end
  end

  it 'renders the reject cta' do
    assert_select 'form[action=?][method=?]', oauth_authorization_grants_path, 'post' do
      assert_select 'input[type=hidden][name=?]', 'state'
      assert_select 'input[type=hidden][name=?][value=?]', 'approve', 'false'
    end
  end

  it 'renders the approve cta' do
    assert_select 'form[action=?][method=?]', oauth_authorization_grants_path, 'post' do
      assert_select 'input[type=hidden][name=?]', 'state'
      assert_select 'input[type=hidden][name=?][value=?]', 'approve', 'true'
    end
  end
end
