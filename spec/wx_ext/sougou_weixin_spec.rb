# encoding: UTF-8
require 'spec_helper'

describe WxExt::SougouWeixin do

  it 'should spider some posts from weixin.sougou.com' do
    spider_posts = WxExt::SougouWeixin.spider_posts_from_sougou('oIWsFt-tphuh--mRkYQI-TePFFBo', 1)
    puts spider_posts[:spider_posts].count
    expect(spider_posts[:original_count]).to eql(10)
  end

  it 'should spider some posts later time' do
    spider_posts = WxExt::SougouWeixin.spider_posts_later_date('oIWsFt-tphuh--mRkYQI-TePFFBo', '2014-01-01')
    puts spider_posts[:spider_posts].count
    expect(spider_posts[:total_pages].to_s).to match(/\d+/)
  end
end