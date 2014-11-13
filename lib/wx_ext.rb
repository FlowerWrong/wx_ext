require "wx_ext/version"
require 'digest'
require 'rest_client'
require 'json'

module WxExt
  class WeiXin
    attr_accessor :account, :password, :home_url, :token, :user_name, :ticket_id, :ticket, :cookies, :operation_seq
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
    def init
      login_name = @account
      password = Digest::MD5.hexdigest @password
      home_url = @home_url

      login_headers = {
          referer: 'https://mp.weixin.qq.com/'
      }
      login_params = {
          username: login_name,
          pwd: password,
          imgcode: '',
          f: 'json'
      }

      login_resource = RestClient::Resource.new(home_url, :headers => login_headers)
      login_res = login_resource['cgi-bin/login'].post login_params, :content_type => 'text/plain'
      login_cookies = login_res.cookies
      login_res_str = login_res.to_s
      # {"base_resp"=>{"ret"=>0, "err_msg"=>"ok"}, "redirect_url"=>"/cgi-bin/home?t=home/index&lang=zh_CN&token=1869497342"}
      # {"base_resp":{"ret":-8,"err_msg":"need verify code"}}
      # https://mp.weixin.qq.com/cgi-bin/verifycode?username=tuodan@thecampus.cc&r=1415774604450
      login_res_hash = JSON.parse login_res_str
      token_reg = /.*token=(\d+)\".*/
      if token_reg =~ login_res_str
        @token = $1
      end

      msg_send_url = "https://mp.weixin.qq.com/cgi-bin/masssendpage?t=mass/send&token=#{@token}&lang=zh_CN"
      msg_send_page = RestClient.get msg_send_url, {cookies: login_cookies}
      @cookies = login_cookies.merge msg_send_page.cookies

      ticket_reg = /.*ticket\s*:\s*\"(\w+)\".*user_name\s*:\s*\"(\w+)\".*nick_name\s*:\s*\"(.*)\".*/m

      operation_seq_reg = /.*operation_seq\s*:\s*\"(\d+)\".*/
      if operation_seq_reg =~ msg_send_page.to_s
        @operation_seq = $1
      end
      if ticket_reg =~ msg_send_page.to_s
        @ticket = $1
        @user_name = @ticket_id= $2
        true
      else
        nil
      end
    end

    # 上传图片素材到素材中心
    def upload_file(file, file_name, folder = "/cgi-bin/uploads")
      upload_url = "https://mp.weixin.qq.com/cgi-bin/filetransfer?action=upload_material&f=json&writetype=doublewrite&groupid=1&ticket_id=#{@ticket_id}&ticket=#{@ticket}&token=#{@token}&lang=zh_CN"
      response = RestClient.post upload_url, :file => file, \
                                             :Filename => file_name, \
                                             :folder => folder
      res_hash = JSON.parse response.to_s
    end

    # 发送单条图文消息到素材中心
    def upload_single_msg(single_msg_params)
      post_single_msg_uri = "cgi-bin/operate_appmsg?t=ajax-response&sub=create&type=10&token=#{@token}&lang=zh_CN"
      post_single_msg_headers = {
          referer: "https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit&action=edit&type=10&isMul=0&isNew=1&lang=zh_CN&token=#{@token}"
      }
      post_single_msg_resource = RestClient::Resource.new(@home_url, headers: post_single_msg_headers, cookies: @cookies)
      post_single_msg_res = post_single_msg_resource[post_single_msg_uri].post single_msg_params
      # {"ret":"0", "msg":"OK"}
      res_hash = JSON.parse post_single_msg_res.to_s
    end

    # 发送多图文到素材中心
    def upload_multi_msg(msg_params)
      post_msg_uri = "cgi-bin/operate_appmsg?t=ajax-response&sub=create&type=10&token=#{@token}&lang=zh_CN"
      post_msg_headers = {
          referer: "https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit&action=edit&type=10&isMul=1&isNew=1&lang=zh_CN&token=#{@token}"
      }
      post_msg_resource = RestClient::Resource.new(@home_url, headers: post_msg_headers, cookies: @cookies)
      post_msg_res = post_msg_resource[post_msg_uri].post msg_params
      # {"ret":"0", "msg":"OK"}
      res_hash = JSON.parse post_msg_res.to_s
    end

    # 群发图文消息
    def broadcast_msg(msg_params)
      post_msg_uri = "cgi-bin/masssend?t=ajax-response&token=#{@token}&lang=zh_CN"
      post_msg_headers = {
          referer: "https://mp.weixin.qq.com/cgi-bin/masssendpage?t=mass/send&token=#{token}&lang=zh_CN",
          host: 'mp.weixin.qq.com'
      }
      post_msg_resource = RestClient::Resource.new(@home_url, :headers => post_msg_headers, cookies: @cookies)
      post_msg_res = post_msg_resource[post_msg_uri].post msg_params
      # {"ret":"0", "msg":"OK"}
      puts post_msg_res.to_s
      res_hash = JSON.parse post_msg_res.to_s
    end

    # 获取所有的图文列表
    def get_app_msg_list(msg_begin = 0, msg_count = 10)
      app_msg_url = "https://mp.weixin.qq.com/cgi-bin/appmsg?type=10&action=list&begin=#{msg_begin}&count=#{msg_count}&f=json&token=#{@token}&lang=zh_CN&token=#{@token}&lang=zh_CN&f=json&ajax=1&random=#{rand}"
      msg_json = RestClient.get app_msg_url, {cookies: @cookies}
      app_msg_hash = JSON.parse msg_json.to_s
    end
  end
end
