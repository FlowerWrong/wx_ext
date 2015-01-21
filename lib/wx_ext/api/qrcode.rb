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
    module Msg
      # Check the signature before send msg.
      #
      # @return [Boolean] Check the signature true or false.
      def check_signature(signature, timestamp, nonce, token)
        array = [token, timestamp, nonce].sort
        signature == Digest::SHA1.hexdigest(array.join) ? true : false
      end

      extend self
    end
  end
end
