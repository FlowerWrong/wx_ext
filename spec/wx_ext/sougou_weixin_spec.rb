# encoding: UTF-8
require 'spec_helper'
require 'awesome_print'

describe WxExt::SougouWeixin do
  it 'should spider some posts from weixin.sougou.com' do
    domains = '119.29.12.212 203.195.222.118 119.29.107.35'.split(' ')
    spider_posts = WxExt::SougouWeixin.spider_posts_from_sougou('oIWsFt6S9QnZvoC1RZtWxvm-vPQ4', 1, (Time.now - 3600 * 24 * 10).strftime("%Y-%m-%d"), domains.sample)
    ap spider_posts
    expect(spider_posts[:original_count]).to eql(10)
  end

  # it 'should spider some posts later time' do
  #   spider_posts = WxExt::SougouWeixin.spider_posts_later_date('oIWsFt-tphuh--mRkYQI-TePFFBo', '2014-01-01')
  #   expect(spider_posts[:total_pages].to_s).to match(/\d+/)
  # end
end
