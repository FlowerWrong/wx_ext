# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::Js do
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should get js api ticken' do
    jsapi_ticket_hash = WxExt::Api::Js.get_jsapi_ticket(@access_token)
    expect(jsapi_ticket_hash['errcode']).to eql(0)
  end

  #it 'should get js config' do
  #  config_hash = WxExt::Api::Base.get_jsapi_config(@access_token, '', @app_id)
  #  expect(config_hash[:app_id]).to eql(@app_id)
  #end
end
