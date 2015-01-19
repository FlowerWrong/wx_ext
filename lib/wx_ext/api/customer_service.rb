# encoding: UTF-8

module WxExt
  # Weixin api
  #
  # @author FuShengYang
  module Api
    # User api of weixin.
    #
    # @author FuShengYang
    module CustomerService
      class << self
        # Reply msg via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] to_user_openid
        # @param [Enumerable<String>] msg_type
        # @param [Hash] msg_hash
        # @return [Hash] Json based hash.
        def reply_msg(access_token, to_user_openid, msg_type, msg_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/message/custom/send'\
                "?access_token=#{access_token}"
          msg_hash = {
            :touser => to_user_openid,
            :msgtype => msg_type,
            "#{msg_type}".to_sym => msg_hash
          }
          Helper.http_post(url, msg_hash.to_json)
        end
      end
    end
  end
end
