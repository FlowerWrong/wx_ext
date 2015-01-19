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
    module Semantic
      class << self

        # Create semantic search via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] semantic_hash
        # @return [Hash] Json based hash.
        def semantic_search(access_token, semantic_hash)
          url = 'https://api.weixin.qq.com/semantic/semproxy/search'\
                "?access_token=#{access_token}"
          Helper.http_post(url, semantic_hash.to_json)
        end
      end
    end
  end
end
