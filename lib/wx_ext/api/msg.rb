# encoding: UTF-8

module WxExt
  # Weixin api
  #
  # @author FuShengYang
  module Api
    # User api of weixin.
    #
    # @author FuShengYang
    module Qrcode
      class << self

        # Create ticket via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] ticket_hash
        # @return [Hash] Json based hash.
        def create_ticket(access_token, ticket_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/qrcode/create'\
                "?access_token=#{access_token}"
          Helper.http_post(url, ticket_hash.to_json)
        end

        # Get the qrcode via ticket.
        #
        # @param [Enumerable<String>] ticket
        # @return [Hash] Json based hash.
        def get_qrcode_by_ticket(ticket)
          url = 'https://mp.weixin.qq.com/cgi-bin/showqrcode'\
                "?ticket=#{ticket}"
          Helper.http_get url
        end

        # Long url to short url via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] action
        # @param [Enumerable<String>] long_url
        # @return [Hash] Json based hash.
        def long_url_2_short(access_token, action='long2short', long_url)
          url = 'https://api.weixin.qq.com/cgi-bin/shorturl'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { action: action, long_url: long_url }.to_json)
        end
      end
    end
  end
end
