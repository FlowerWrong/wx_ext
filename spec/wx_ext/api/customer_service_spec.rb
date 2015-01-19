# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::CustomerService do
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should reply text msg to user' do
    res_hash = WxExt::Api::CustomerService.reply_msg(@access_token, 'oK_Xnt2a9LAh0cbYuBGFSPxnvu1w', 'text', { content: 'Hello World' })
    puts '=' * 20
    puts res_hash
    expect(res_hash['errcode']).to eql(0)
  end

  it 'should reply img msg to user' do
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    file_hash = WxExt::Api::Base.upload_media(@access_token, 'image', file)
    res_hash = WxExt::Api::CustomerService.reply_msg(@access_token, 'oK_Xnt2a9LAh0cbYuBGFSPxnvu1w', 'image', { media_id: file_hash['media_id'] })
    puts '=' * 20
    puts res_hash
    expect(res_hash['errcode']).to eql(0)
  end
end
