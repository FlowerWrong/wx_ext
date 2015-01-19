# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::Semantic do
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should 发送语义理解请求' do
    semantic_hash = {
      query: '查一下明天从北京到上海的南航机票',
      city: '北京',
      category: 'flight,hotel',
      appid: @app_id,
      uid: 'oK_Xnt2a9LAh0cbYuBGFSPxnvu1w'
    }
    hash = WxExt::Api::Semantic.semantic_search(@access_token, semantic_hash)
    puts hash
    expect(hash['errcode']).to eql(0)
  end
end
