# encoding: UTF-8

module WxExt
  module Api

    # 微信扩展接口, 模拟登陆微信公众平台
    # @author FuShengYang
    module Menu
      class << self

        def create_menu(access_token, menu_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/menu/create'\
                "?access_token=#{access_token}"
          Helper.http_post(url, menu_hash)
        end

        def menus(access_token)
          url = 'https://api.weixin.qq.com/cgi-bin/menu/get'\
                "?access_token=#{access_token}"
          Helper.http_get(url, { accept: :json })
        end

        def del_menu(access_token)
          url = 'https://api.weixin.qq.com/cgi-bin/menu/delete'\
                "?access_token=#{access_token}"
          Helper.http_get(url, { accept: :json })
        end
      end
    end
  end
end
