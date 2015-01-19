# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::Menu do
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should create menu and then del it' do
    menu_hash = {
      button: [
        {
          type: 'click',
          name: '今日歌曲',
          key: 'V1001_TODAY_MUSIC'
        },
        {
          name: '菜单',
          sub_button: [
            {
              type: 'view',
              name: '搜索',
              url: 'http://www.soso.com/'
            },
            {
              type: 'view',
              name: '视频',
              url: 'http://v.qq.com/'
            },
            {
              type: 'click',
              name: '赞一下我们',
              key: 'V1001_GOOD'
            }
          ]
        }
      ]
    }
    create_hash = WxExt::Api::Menu.create_menu(@access_token, menu_hash)
    puts '=' * 20
    puts create_hash
    expect(create_hash['errcode']).to eql(0)
  end

  it 'should get all menus and then del it' do
    res_hash = WxExt::Api::Menu.menus(@access_token)
    puts '=' * 20
    puts res_hash
    expect(res_hash['menu']).not_to be_empty

    del_hash = WxExt::Api::Menu.del_menu(@access_token)
    expect(del_hash['errcode']).to eql(0)
    puts del_hash
  end
end
