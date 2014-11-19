# encoding: UTF-8
require 'wx_ext/version'
require 'digest'
require 'rest_client'
require 'json'
require 'nokogiri'

module WxExt
  class WeiXin
    attr_accessor :account, :password, :home_url, :token, :user_name, \
                  :ticket_id, :ticket, :cookies, :operation_seq
    def initialize(account, password)
      @account = account
      @password = password
      @home_url = 'https://mp.weixin.qq.com'
      @token = nil
      @ticket = nil
      @user_name = nil
      @ticket_id = nil
      @cookies = {}
      @operation_seq = ''
    end

    # 使用用户名和密码登陆微信公众平台获取access_token, 过期时间是7200s
    def login
      password = Digest::MD5.hexdigest @password
      login_headers = {
        referer: 'https://mp.weixin.qq.com/'
      }
      login_params = {
        username: @account,
        pwd: password,
        imgcode: '',
        f: 'json'
      }

      resource = RestClient::Resource.new(@home_url, headers: login_headers)
      res = resource['cgi-bin/login'].post login_params
      @cookies = res.cookies
      return_hash = {
        status: 0,
        msg: 'ok'
      }
      # {"base_resp"=>{"ret"=>0, "err_msg"=>"ok"}, "redirect_url"=>"/cgi-bin/home?t=home/index&lang=zh_CN&token=1869497342"}
      # {"base_resp":{"ret":-8,"err_msg":"need verify code"}}
      # https://mp.weixin.qq.com/cgi-bin/verifycode?username=tuodan@thecampus.cc&r=1415774604450
      res_hash = JSON.parse res.to_s
      if res_hash['base_resp']['ret'].to_s == '0'
        token_reg = /.*token=(\d+)\".*/
        @token = $1 if token_reg =~ res.to_s
      elsif res_hash['bash_resp']['ret'].to_s == '-8'
        return_hash = {
          status: -8,
          msg: 'need_varify_code'
        }
      else
        return_hash = {
          status: -1,
          msg: 'system_error'
        }
      end
      return_hash
    end

    # 初始化 ticket, cookies, operation_seq, user_name 等等信息
    def init
      msg_send_url = 'https://mp.weixin.qq.com/cgi-bin/masssendpage'\
                     "?t=mass/send&token=#{@token}&lang=zh_CN"
      msg_send_page = RestClient.get msg_send_url, cookies: @cookies
      @cookies = @cookies.merge msg_send_page.cookies

      ticket_reg = /.*ticket\s*:\s*\"(\w+)\".*user_name\s*:\s*\"(\w+)\".*nick_name\s*:\s*\"(.*)\".*/m
      operation_seq_reg = /.*operation_seq\s*:\s*\"(\d+)\".*/
      @operation_seq = $1 if operation_seq_reg =~ msg_send_page.to_s
      if ticket_reg =~ msg_send_page.to_s
        @ticket = $1
        @user_name = @ticket_id= $2
        true
      else
        false
      end
    end

    # 上传图片素材到素材中心
    def upload_file(file, file_name, folder = '/cgi-bin/uploads')
      upload_url = "https://mp.weixin.qq.com/cgi-bin/filetransfer?action=upload_material&f=json&writetype=doublewrite&groupid=1&ticket_id=#{@ticket_id}&ticket=#{@ticket}&token=#{@token}&lang=zh_CN"
      response = RestClient.post upload_url, file: file, \
                                             Filename: file_name, \
                                             folder: folder
      JSON.parse response.to_s
    end

    # 发送单条图文消息到素材中心
    def upload_single_msg(single_msg_params)
      post_single_msg_uri = 'cgi-bin/operate_appmsg'\
                            '?t=ajax-response&sub=create&type=10&token'\
                            "=#{@token}&lang=zh_CN"
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit'\
                 '&action=edit&type=10&isMul=0&isNew=1&lang=zh_CN'\
                 "&token=#{@token}"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers,
                                                     cookies: @cookies)
      res = resource[post_single_msg_uri].post single_msg_params
      # {"ret":"0", "msg":"OK"}
      JSON.parse res.to_s
    end

    # 发送多图文到素材中心
    def upload_multi_msg(msg_params)
      uri = 'cgi-bin/operate_appmsg?t=ajax-response&sub=create&type=10'\
                     "&token=#{@token}&lang=zh_CN"
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/appmsg'\
                 '?t=media/appmsg_edit&action=edit&type=10'\
                 "&isMul=1&isNew=1&lang=zh_CN&token=#{@token}"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers,
                                                     cookies: @cookies)
      post_msg_res = resource[uri].post msg_params
      # {"ret":"0", "msg":"OK"}
      JSON.parse post_msg_res.to_s
    end

    # 群发图文消息
    def broadcast_msg(msg_params)
      uri = "cgi-bin/masssend?t=ajax-response&token=#{@token}&lang=zh_CN"
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/masssendpage'\
                 "?t=mass/send&token=#{token}&lang=zh_CN",
        host: 'mp.weixin.qq.com'
      }
      resource = RestClient::Resource.new(@home_url, headers: headers,
                                                     cookies: @cookies)
      post_msg_res = resource[uri].post msg_params
      # {"ret":"0", "msg":"OK"}
      JSON.parse post_msg_res.to_s
    end

    # 获取所有的图文列表
    def get_app_msg_list(msg_begin = 0, msg_count = 10)
      url = 'https://mp.weixin.qq.com/cgi-bin/appmsg?type=10&action=list'\
            "&begin=#{msg_begin}&count=#{msg_count}&f=json&token=#{@token}"\
            "&lang=zh_CN&token=#{@token}&lang=zh_CN&f=json&ajax=1"\
            "&random=#{rand}"
      msg_json = RestClient.get url, cookies: @cookies
      JSON.parse msg_json.to_s
    end

		# 轮训新消息条数
		def get_new_msg_num(last_msg_id)
      uri = 'cgi-bin/getnewmsgnum?f=json&t=ajax-getmsgnum'\
            "&lastmsgid=#{last_msg_id}&token=#{@token}&lang=zh_CN"
      post_params = {
        ajax: 1,
        f: 'json',
        lang: 'zh_CN',
        random: rand,
        token: @token
      }
      post_headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/message?t=message/list'\
                 "&count=20&day=7&token=#{@token}&lang=zh_CN"
      }
      resource = RestClient::Resource.new(@home_url, headers: post_headers,
                                                     cookies: @cookies)
      res = resource[uri].post post_params
      JSON.parse res.to_s
		end

		# 获取联系人信息
		def get_contact_info(fakeid)
      uri = 'cgi-bin/getcontactinfo?t=ajax-getcontactinfo'\
            "&lang=zh_CN&fakeid=#{fakeid}"
      post_params = {
        ajax: 1,
        f: 'json',
        lang: 'zh_CN',
        random: rand,
        token: @token
      }
      post_headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/contactmanage?t=user/index'\
                 "&pagesize=10&pageidx=0&type=0&token=#{@token}&lang=zh_CN"
      }
      resource = RestClient::Resource.new(@home_url, headers: post_headers,
                                                     cookies: @cookies)
      res = resource[uri].post post_params
      JSON.parse res.to_s
	  end

    # 获取国家列表
    def get_country_list
      url = 'https://mp.weixin.qq.com/cgi-bin/getregions'\
            "?t=setting/ajax-getregions&id=0&token=#{@token}&lang=zh_CN"\
            "&token=#{@token}&lang=zh_CN&f=json&ajax=1&random=#{rand}"
      resource = RestClient::Resource.new(url, cookies: @cookies)
      res = resource.get
      JSON.parse res.to_s
    end

    # 获取每日可推送消息数
    def get_day_msg_count
      url = 'https://mp.weixin.qq.com/cgi-bin/masssendpage'\
            "?t=mass/send&token=#{@token}&lang=zh_CN"
      res = RestClient.get(url, cookies: @cookies)
      day_msg_count = 0
      reg = /.*mass_send_left\s*:\s*can_verify_apply\s*\?\s*\'(\d*)\'\*/
      day_msg_count = $1 if reg =~ res.to_s
      day_msg_count.to_i
    end

    # 获取 last_msg_id 和 msg_item
    def get_msg_item
      url = 'https://mp.weixin.qq.com/cgi-bin/message?t=message/list&count=20'\
            "&day=7&token=#{@token}&lang=zh_CN"
      resource = RestClient::Resource.new(url, cookies: @cookies)
      res = resource.get
      reg = /.*total_count\s*:\s*(\d*).*latest_msg_id\s*:\s*\'(\d*)\'.*list\s*:\s*\((.*)\)\.msg_item,.*/m
      return_hash = {
        status: -1,
        msg: 'system_error'
      }
      if reg =~ res.to_s
        return_hash = {
          status: 0,
          msg: 'ok',
          total_count: $1,
          latest_msg_id: $2,
          msg_item: JSON.parse($3)['msg_item']
        }
      end
      return_hash
    end

		# https://mp.weixin.qq.com/cgi-bin/message?t=message/list&token=1664040225&count=20&day=7
		# https://mp.weixin.qq.com/cgi-bin/message?t=message/list&count=20&day=7&token=1664040225&lang=zh_CN

		# https://mp.weixin.qq.com/cgi-bin/singlesend?t=ajax-response&f=json&token=1664040225&lang=zh_CN
		def quick_reply
		end

		# https://mp.weixin.qq.com/cgi-bin/setstarmessage?t=ajax-setstarmessage&token=1664040225&lang=zh_CN
		def collect_msg
    end

    private

    def set_cookie(page, k, v)
      case Capybara.current_session.driver
      when Capybara::Poltergeist::Driver
        page.driver.set_cookie(k, v)
      when Capybara::RackTest::Driver
        headers = {}
        Rack::Utils.set_cookie_header!(headers, k, v)
        cookie_string = headers['Set-Cookie']
        Capybara.current_session.driver.browser.set_cookie(cookie_string)
      when Capybara::Selenium::Driver
        page.driver.browser.manage.add_cookie(name: k, value: v)
      else
        fail 'no cookie-setter implemented for driver '\
              "#{Capybara.current_session.driver.class.name}"
      end
    end
  end
end
