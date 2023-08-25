# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'sessions/new' do
  it 'renders log in form' do
    render

    assert_select 'form[action=?][method=?]', sign_in_path, 'post' do
      assert_select 'input[name=?]', 'email'
      assert_select 'input[name=?]', 'password'
    end
  end
end
