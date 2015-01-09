# encoding: UTF-8
require 'spec_helper'

describe WxExt::SougouWeixin do

  it 'should spider some posts from weixin.sougou.com' do
    spider_posts = WxExt::SougouWeixin.spider_posts_from_sougou('oIWsFt-tphuh--mRkYQI-TePFFBo', 1)
    puts spider_posts
    expect(spider_posts[:original_count]).to eql(10)
  end
end