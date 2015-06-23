# encoding: UTF-8

require 'wx_ext/version'
require 'wx_ext/sougou_weixin'
require 'wx_ext/wei_xin'
require 'wx_ext/wechat_pay'
require 'wx_ext/api'

# Weixin extention, sougou spider and weixin api.
#
# @author FuShengYang
module WxExt
  module_function

  # Return the root path of this gem.
  #
  # @return [String] Path of the gem's root.
  def root
    File.dirname __dir__
  end

  # Return the lib path of this gem.
  #
  # @return [String] Path of the gem's lib.
  def lib
    File.join root, 'lib'
  end

  # Return the spec path of this gem.
  #
  # @return [String] Path of the gem's spec.
  def spec
    File.join root, 'spec'
  end
end
