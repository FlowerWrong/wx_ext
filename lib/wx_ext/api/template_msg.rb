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
    module TemplateMsg
      # Set the industry via post.
      #
      # @param [Enumerable<String>] access_token
      # @param [Enumerable<String>] industry_id1
      # @param [Enumerable<String>] industry_id2
      # @return [Hash] Json based hash.
      def set_industry(access_token, industry_id1, industry_id2)
        url = 'https://api.weixin.qq.com/cgi-bin/template/api_set_industry'\
              "?access_token=#{access_token}"
        Helper.http_post(url, { industry_id1: industry_id1, industry_id2: industry_id2 }.to_json)
      end

      # Get the template ID via post.
      #
      # @param [Enumerable<String>] access_token
      # @param [Enumerable<String>] template_id_short
      # @return [Hash] Json based hash.
      def get_template_id(access_token, template_id_short)
        url = 'https://api.weixin.qq.com/cgi-bin/template/api_add_template'\
              "?access_token=#{access_token}"
        Helper.http_post(url, { template_id_short: template_id_short })
      end

      # Send the template msg via post.
      #
      # @param [Enumerable<String>] access_token
      # @param [Hash] template_msg_hash
      # @return [Hash] Json based hash.
      def send_template_msg(access_token, template_msg_hash)
        url = 'https://api.weixin.qq.com/cgi-bin/message/template/send'\
              "?access_token=#{access_token}"
        Helper.http_post(url, template_msg_hash.to_json)
      end

      extend self
    end
  end
end
