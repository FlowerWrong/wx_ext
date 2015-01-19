# encoding: UTF-8

require 'rest_client'
require 'json'

module WxExt

  # @author FuShengYang
  module Helper
    class << self
      def http_get(url, headers = {})
        res = RestClient.get url, headers
        JSON.parse res
      end

      def http_post(url, params, headers = {})
        res = RestClient.post url, params, headers
        JSON.parse res
      end
    end
  end
end
