# encoding: UTF-8

require 'digest'

module WxExt
  module Api

    # 微信扩展接口, 模拟登陆微信公众平台
    # @author FuShengYang
    module Msg
      class << self

        def check_signature(signature, timestamp, nonce, token)
          array = [token, timestamp, nonce].sort
          signature == Digest::SHA1.hexdigest(array.join) ? true : false
        end
      end
    end
  end
end
