# encoding: UTF-8

require 'rest_client'
require 'json'

module WxExt
  # WxExt Helper like get and post short method.
  #
  # @author FuShengYang
  module Helper
    class << self
      # Http get helper of this gem, always return a hash.
      #
      # @param [Enumerable<String>] url
      # @param [Hash] headers
      # @return [Hash] A json parse hash.
      def http_get(url, headers = {})
        res = RestClient.get url, headers
        JSON.parse res
      end

      # Http post helper of this gem, always return a hash.
      #
      # @param [Enumerable<String>] url
      # @param [Hash] params
      # @param [Hash] headers
      # @return [Hash] A json parse hash.
      def http_post(url, params, headers = {})
        res = RestClient.post url, params, headers
        JSON.parse res
      end
    end
  end
end
