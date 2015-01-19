# encoding: UTF-8

require 'wx_ext/version'
require 'wx_ext/sougou_weixin'
require 'wx_ext/wei_xin'
require 'wx_ext/api'

# 微信扩展接口和基本接口
# @author FuShengYang
module WxExt
  def self.root
    File.dirname __dir__
  end

  def self.lib
    File.join root, 'lib'
  end

  def self.spec
    File.join root, 'spec'
  end
end
