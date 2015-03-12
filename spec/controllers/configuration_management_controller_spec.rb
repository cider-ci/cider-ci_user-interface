require 'spec_helper'

describe ::ConfigurationManagementController, type: :controller do
  it 'requires authentication' do
    post :invoke, '1 + 1'
    expect(response.status).to eq 401
  end

  it 'accepts the secret_key_base as password ' do
    @request.env['HTTP_AUTHORIZATION'] =  \
      ActionController::HttpAuthentication::Basic.encode_credentials( \
        'irrelevant', Rails.application.secrets.secret_key_base)
    @request.env['CONTENT_TYPE'] = 'application/ruby'
    post :invoke, '1 + 1'
    expect(response.status).to eq 200
  end

  it 'evaluates ruby' do
    @request.env['HTTP_AUTHORIZATION'] =  \
      ActionController::HttpAuthentication::Basic.encode_credentials( \
        'irrelevant', Rails.application.secrets.secret_key_base)
    @request.env['CONTENT_TYPE'] = 'application/ruby'
    post :invoke, '40 + 2'
    expect(response.status).to eq 200
    expect(Integer(response.body)).to eq 42
  end

  it 'evaluates sql' do
    @request.env['HTTP_AUTHORIZATION'] =  \
      ActionController::HttpAuthentication::Basic.encode_credentials( \
        'irrelevant', Rails.application.secrets.secret_key_base)
    @request.env['CONTENT_TYPE'] = 'application/sql'
    post :invoke, 'SELECT 40 + 2;'
    expect(response.status).to eq 200
    expect(response.body).to have_content '42'
  end

end
