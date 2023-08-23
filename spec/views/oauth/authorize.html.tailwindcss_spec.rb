# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'oauth/authorize' do
  it 'renders log in form' do
    render template: 'oauth/authorize', locals: { state: 'state token' }

    assert_select 'form[action=?][method=?]', authenticate_path, 'post' do
      assert_select 'input[type=hidden][name=?]', 'state'
      assert_select 'input[name=?]', 'email'
      assert_select 'input[name=?]', 'password'
    end
  end
end
