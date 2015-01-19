# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::User do
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should get user list' do
    user_list_hash = WxExt::Api::User.user_list(@access_token)
    puts '-' * 20
    puts user_list_hash
    expect(user_list_hash['total'].to_s).to match(/\d*/)
  end

  it 'should get user info of oK_Xnt2a9LAh0cbYuBGFSPxnvu1w' do
    user_hash = WxExt::Api::User.get_user_base_info(@access_token, 'oK_Xnt2a9LAh0cbYuBGFSPxnvu1w')
    puts '-' * 20
    puts user_hash
    expect(user_hash['sex'].to_s).to match(/\d*/)
  end

  it 'should get user info of 南' do
    user_list_hash = WxExt::Api::User.user_list(@access_token)
    user_list_hash['data']['openid'].each do |openid|
      user_hash = WxExt::Api::User.get_user_base_info(@access_token, openid)
      if user_hash['nickname'] == '南'
        puts '-' * 20
        # oK_Xnt2a9LAh0cbYuBGFSPxnvu1w
        puts user_hash
      end
    end
    expect(user_list_hash['total'].to_s).to match(/\d*/)
  end

  it 'should remark nickname of 南' do
    remark_hash = WxExt::Api::User.change_remark(@access_token, 'oK_Xnt2a9LAh0cbYuBGFSPxnvu1w', 'good boy')
    expect(remark_hash['errcode']).to eql(0)
  end
end
