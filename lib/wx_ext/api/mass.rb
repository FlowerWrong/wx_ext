# encoding: UTF-8

module WxExt
  # Weixin api
  #
  # @author FuShengYang
  module Api
    # User api of weixin.
    #
    # @author FuShengYang
    module Mass
      class << self
        # Upload news to weixin server via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] news_hash
        # @return [Hash] Json based hash.
        def upload_news(access_token, news_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/media/uploadnews'\
                "?access_token=#{access_token}"
          Helper.http_post(url, news_hash.to_json)
        end

        # Mass to users by filter group via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] filter_hash
        # @return [Hash] Json based hash.
        def mass_by_filter_group(access_token, filter_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/message/mass/sendall'\
                "?access_token=#{access_token}"
          Helper.http_post(url, filter_hash.to_json)
        end

        # Mass to users by openid via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] openid_hash
        # @return [Hash] Json based hash.
        def mass_by_openid(access_token, openid_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/message/mass/send'\
                "?access_token=#{access_token}"
          Helper.http_post(url, openid_hash.to_json)
        end

        # Del mass via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [String] msg_id
        # @return [Hash] Json based hash.
        def del_mass(access_token, msg_id)
          url = 'https://api.weixin.qq.com/cgi-bin/message/mass/delete'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { msg_id: msg_id }.to_json)
        end

        # Preview mass via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [Hash] preview_hash
        # @return [Hash] Json based hash.
        def preview_mass(access_token, preview_hash)
          url = 'https://api.weixin.qq.com/cgi-bin/message/mass/preview'\
                "?access_token=#{access_token}"
          Helper.http_post(url, preview_hash.to_json)
        end

        # Get mass status via post.
        #
        # @param [Enumerable<String>] access_token
        # @param [String] msg_id
        # @return [Hash] Json based hash.
        def get_mass_status(access_token, msg_id)
          url = 'https://api.weixin.qq.com/cgi-bin/message/mass/get'\
                "?access_token=#{access_token}"
          Helper.http_post(url, { msg_id: msg_id }.to_json)
        end
      end
    end
  end
end
