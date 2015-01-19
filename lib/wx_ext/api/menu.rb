# encoding: UTF-8

module WxExt
  # Weixin api
  #
  # @author FuShengYang
  module Api
    # User api of weixin.
    #
    # @author FuShengYang
    module Menu
      class << self

        # Create menu via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] menu_hash
        # @return [Hash] Json based hash.
        def create_menu(access_token, menu_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/menu/create'\
                "?access_token=#{access_token}"
          Helper.http_post(url, menu_hash.to_json)
        end

        # Get menus via get.
        #
        # @param [Enumerable<String>] access_token
        # @return [Hash] Json based hash.
        def menus(access_token)
          url = 'https://api.weixin.qq.com/cgi-bin/menu/get'\
                "?access_token=#{access_token}"
          Helper.http_get(url, { accept: :json })
        end

        # Del menu via get.
        #
        # @param [Enumerable<String>] access_token
        # @return [Hash] Json based hash.
        def del_menu(access_token)
          url = 'https://api.weixin.qq.com/cgi-bin/menu/delete'\
                "?access_token=#{access_token}"
          Helper.http_get(url, { accept: :json })
        end
      end
    end
  end
end
