# encoding: UTF-8

require 'wx_ext/helper'

module WxExt
  # Weixin api
  #
  # @author FuShengYang
  module Api
    # User api of weixin.
    #
    # @author FuShengYang
    module User
      class << self

        # Change the remark of user via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] openid
        # @param [Enumerable<String>] remark
        # @return [Hash] Json based hash.
        def change_remark(access_token, openid, remark)
          url = 'https://api.weixin.qq.com/cgi-bin/user/info/updateremark'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { openid: openid, remark: remark }.to_json)
        end

        # Get the user base info.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] openid
        # @param [Enumerable<String>] lang
        # @return [Hash] Json based hash.
        def get_user_base_info(access_token, openid, lang='zh_CN')
          url = 'https://api.weixin.qq.com/cgi-bin/user/info'\
                "?access_token=#{access_token}&openid=#{openid}&lang=#{lang}"
          Helper.http_get(url, { accept: :json })
        end

        # Get user list of weixin.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] next_openid
        # @return [Hash] Json based hash.
        def user_list(access_token, next_openid=nil)
          url = 'https://api.weixin.qq.com/cgi-bin/user/get'\
                "?access_token=#{access_token}"
          url += "&next_openid=#{next_openid}" if next_openid
          Helper.http_get(url, { accept: :json })
        end

        # Get oauth2 token with code.
        #
        # @param [Enumerable<String>] app_id
        # @param [Enumerable<String>] app_secret
        # @param [Enumerable<String>] code
        # @param [Enumerable<String>] grant_type
        # @return [Hash] Json based hash.
        def get_oauth2_token_with_code(app_id, app_secret, code, grant_type='authorization_code')
          url = 'https://api.weixin.qq.com/sns/oauth2/access_token'\
                "?appid=#{app_id}&secret=#{app_secret}&code=CODE&grant_type=#{grant_type}"
          Helper.http_get(url, { accept: :json })
        end

        # Refresh oauth2 token.
        #
        # @param [Enumerable<String>] app_id
        # @param [Enumerable<String>] refresh_token
        # @param [Enumerable<String>] grant_type
        # @return [Hash] Json based hash.
        def refresh_oauth2_token(app_id, refresh_token, grant_type='refresh_token')
          url = 'https://api.weixin.qq.com/sns/oauth2/refresh_token'\
                "?appid=#{app_id}&grant_type=#{grant_type}&refresh_token=#{refresh_token}"
          Helper.http_get(url, { accept: :json })
        end

        # Get user info with snsapi_userinfo.
        #
        # @param [Enumerable<String>] oauth2_token
        # @param [Enumerable<String>] openid
        # @param [Enumerable<String>] lang
        # @return [Hash] Json based hash.
        def get_user_info_with_snsapi_userinfo(oauth2_token, openid, lang)
          url = 'https://api.weixin.qq.com/sns/userinfo'\
                "?access_token=#{oauth2_token}&#{openid}=OPENID&lang=#{lang}"
          Helper.http_get(url, { accept: :json })
        end

        # Check the oauth2_token.
        #
        # @param [Enumerable<String>] openid
        # @param [Enumerable<String>] oauth2_token
        # @return [Hash] Json based hash.
        def check_oauth2_token(openid, oauth2_token)
          url = 'https://api.weixin.qq.com/sns/auth'\
                "?access_token=#{oauth2_token}&openid=#{openid}"
          Helper.http_get(url, { accept: :json })
        end
      end
    end
  end
end
