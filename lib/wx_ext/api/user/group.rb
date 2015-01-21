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
      # User group api of weixin.
      #
      # @author FuShengYang
      module Group
        # Create user group via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] group_name
        # @return [Hash] A json parse hash.
        def create_group(access_token, group_name)
          url = 'https://api.weixin.qq.com/cgi-bin/groups/create'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { group: { name: group_name } }.to_json)
        end

        # Get all groups via get.
        #
        # @param [Enumerable<String>] access_token
        # @return [Hash] A json parse hash.
        def groups(access_token)
          url = 'https://api.weixin.qq.com/cgi-bin/groups/get'\
                "?access_token=#{access_token}"
          Helper.http_get(url, { accept: :json }.to_json)
        end

        # Get user of group via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] openid
        # @return [Hash] A json parse hash.
        def user_of_group(access_token, openid)
          url = 'https://api.weixin.qq.com/cgi-bin/groups/getid'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { openid: openid }.to_json)
        end

        # Update user group name via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] id
        # @param [Enumerable<String>] name
        # @return [Hash] A json parse hash.
        def update_group_name(access_token, id, name)
          url = 'https://api.weixin.qq.com/cgi-bin/groups/update'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { group: { id: id, name: name } }.to_json)
        end

        # Move user group via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Enumerable<String>] openid
        # @param [Enumerable<String>] to_groupid
        # @return [Hash] A json parse hash.
        def mv_user_group(access_token, openid, to_groupid)
          url = 'https://api.weixin.qq.com/cgi-bin/groups/members/update'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { openid: openid, to_groupid: to_groupid }.to_json)
        end

        extend self
      end
    end
  end
end
