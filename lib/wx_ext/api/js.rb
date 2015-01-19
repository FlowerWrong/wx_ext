# encoding: UTF-8

require 'digest'
require 'rest_client'
require 'json'

module WxExt
  module Api

    # 微信扩展接口, 模拟登陆微信公众平台
    # @author FuShengYang
    module Js
      class << self
        def get_jsapi_ticket(access_token)
          url = "https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=#{access_token}&type=jsapi"
          Helper.http_get(url, { accept: :json })
        end

        def get_jsapi_config(access_token, url, app_id)
          config_hash = {}
          jsapi_ticket_hash = get_jsapi_ticket(access_token)
          timestamp = set_timestamp
          noncestr = set_noncestr
          if jsapi_ticket_hash['errcode'] == 0
            jsapi_ticket = jsapi_ticket_hash['ticket']
            str = "jsapi_ticket=#{jsapi_ticket}&noncestr=#{noncestr}&timestamp=#{timestamp}&url=#{url}"
            signature = Digest::SHA1.hexdigest(str)
            config_hash = {
              app_id: app_id,
              timestamp: timestamp,
              noncestr: noncestr,
              signature: signature
            }
          end
          config_hash
        end

        private

        def set_noncestr
          [*'a'..'z',*'0'..'9',*'A'..'Z'].sample(16).join
        end

        def set_timestamp
          Time.now.to_i.to_s
        end
      end
    end
  end
end
