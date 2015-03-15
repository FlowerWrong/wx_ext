# encoding: UTF-8
require 'spec_helper'

describe WxExt::WechatPay do
  before(:all) do
  end

  it 'should login to the mp' do
    res_hash = @weixin.login
    puts res_hash
    expect(res_hash[:status]).to eql(0)
  end
end
