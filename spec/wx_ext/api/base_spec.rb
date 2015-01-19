# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::Base do
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should get access_token' do
    expect(@access_token_hash['expires_in']).to eql(7200)
  end

  it 'should get weixin ip list' do
    res_hash = WxExt::Api::Base.get_weixin_ips(@access_token)
    puts '=' * 20
    puts res_hash
    expect(res_hash['ip_list']).not_to be_empty
  end

  it 'should return a code and msg hash' do
    res_hash = WxExt::Api::Base.code_msg
    puts '=' * 20
    puts res_hash
    expect(res_hash).not_to be_empty
  end

  it 'should upload a media to weixin' do
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    res_hash = WxExt::Api::Base.upload_media(@access_token, 'image', file)
    puts '=' * 20
    puts res_hash
    expect(res_hash['created_at'].to_s).to match(/\d*/)
  end

  it 'should download a media from weixin' do
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    res_hash = WxExt::Api::Base.upload_media(@access_token, 'image', file)
    expect(res_hash['created_at'].to_s).to match(/\d*/)
    WxExt::Api::Base.download_media(@access_token, res_hash['media_id'])
  end
end
