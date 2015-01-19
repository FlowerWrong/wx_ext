# encoding: UTF-8

require 'digest'
require 'rest_client'
require 'json'
require 'wx_ext/api/user/group'

module WxExt
  module Api

    # 微信扩展接口, 模拟登陆微信公众平台
    # @author FuShengYang
    module User
      class << self
        def change_remark(access_token, openid, remark) end

        def get_user_base_info(access_token, openid, lang) end

        def user_list(access_token, next_openid) end

        def get_oauth2_token_with_code(app_id, app_secret, code, grant_type='authorization_code')
          url = 'https://api.weixin.qq.com/sns/oauth2/access_token'\
                "?appid=#{app_id}&secret=#{app_secret}&code=CODE&grant_type=#{grant_type}"
          Helper.http_get(url, { accept: :json })
        end

        def refresh_oauth2_token(app_id, refresh_token, grant_type='refresh_token')
          url = 'https://api.weixin.qq.com/sns/oauth2/refresh_token'\
                "?appid=#{app_id}&grant_type=#{grant_type}&refresh_token=#{refresh_token}"
          Helper.http_get(url, { accept: :json })
        end

        def get_user_info_with_snsapi_userinfo(oauth2_token, openid, lang)
          url = 'https://api.weixin.qq.com/sns/userinfo'\
                "?access_token=#{oauth2_token}&#{openid}=OPENID&lang=#{lang}"
          Helper.http_get(url, { accept: :json })
        end

        def check_oauth2_token(openid, oauth2_token)
          url = 'https://api.weixin.qq.com/sns/auth'\
                "?access_token=#{oauth2_token}&openid=#{openid}"
          Helper.http_get(url, { accept: :json })
        end
      end
    end
  end
end
