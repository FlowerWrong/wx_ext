# encoding: UTF-8

require 'digest'
require 'rest_client'
require 'json'
require 'nokogiri'
require 'uri'

class String
  def remove_unmatched_parens
    self[/
          (?<valid>
            \(\g<valid>*\)
            |[^()]
          )+
        /x]
  end
end

module WxExt
  # weixin extention of mp.weixin.qq.com
  #
  # @author FuShengYang
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

    # 模拟登陆微信公众平台, 初始化 access_token, cookies
    #
    # @return [Hash] Hash with login status and msg.
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

      # 0: "ok", "redirect_url" => ""
      # -8: "need verify code"
      # -23: "acct\/password error"
      # -21: "user not exist"
      res_hash = JSON.parse res.to_s
      sta = res_hash['base_resp']['ret'].to_s
      if sta == '0'
        token_reg = /.*token=(\d+)\".*/
        @token = $1 if token_reg =~ res.to_s
      elsif sta == '-8'
        return_hash = {
          status: -8,
          msg: 'need_varify_code'
        }
      elsif sta == '-23'
        return_hash = {
          status: -23,
          msg: 'password_error'
        }
      elsif sta == '-21'
        return_hash = {
          status: -21,
          msg: 'user_not_exist'
        }
      else
        return_hash = {
          status: -1,
          msg: 'system_error'
        }
      end
      return_hash
    end

    # Init ticket, cookies, operation_seq, user_name etc.
    #
    # @return [Boolean] Init ticket, cookies, operation_seq, user_name true or false.
    def init
      home_url = "https://mp.weixin.qq.com/cgi-bin/home?t=home/index&lang=zh_CN&token=#{@token}"
      headers = {
        host: 'mp.weixin.qq.com',
        referer: 'https://mp.weixin.qq.com/'
      }

      @cookies = {
        data_bizuin: URI.unescape(cookies['data_bizuin']),
        data_ticket: URI.unescape(cookies['data_ticket']),
        slave_user: URI.unescape(cookies['slave_user']),
        slave_sid: URI.unescape(cookies['slave_sid']),
        bizuin: URI.unescape(cookies['bizuin'])
      }

      msg_send_url = 'https://mp.weixin.qq.com/cgi-bin/masssendpage'\
                     "?t=mass/send&token=#{@token}&lang=zh_CN"
      msg_send_page = RestClient.get msg_send_url, cookies: @cookies

      ticket_reg = /.*ticket\s*:\s*\"(\w+)\".*user_name\s*:\s*\"(.*)\",.*nick_name\s*:\s*\"(.*)\".*/m
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

    # Upload file to file.weixin.qq.com
    #
    # @param [File] file
    # @param [String] file_name
    # @param [String] folder
    # @return [Hash] A json parse hash.
    def upload_file(file, file_name, folder = '/cgi-bin/uploads')
      upload_url = 'https://mp.weixin.qq.com/cgi-bin/filetransfer'\
                   '?action=upload_material&f=json&writetype=doublewrite'\
                   "&groupid=1&ticket_id=#{@ticket_id}"\
                   "&ticket=#{@ticket}&token=#{@token}&lang=zh_CN"
      response = RestClient.post upload_url, file: file,
                                             Filename: file_name,
                                             folder: folder
      JSON.parse response.to_s
    end

    # Upload single news to mp.weixin.qq.com
    #
    # @param [Hash] single_msg_params
    # @return [Hash] A json parse hash.
    def upload_single_msg(single_msg_params)
      post_single_msg_uri = 'cgi-bin/operate_appmsg'\
                            '?t=ajax-response&sub=create&type=10&token'\
                            "=#{@token}&lang=zh_CN"
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit'\
                 '&action=edit&type=10&isMul=0&isNew=1&lang=zh_CN'\
                 "&token=#{@token}"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers, cookies: @cookies)
      res = resource[post_single_msg_uri].post single_msg_params
      JSON.parse res.to_s
    end

    # Upload multi news to mp.weixin.qq.com
    #
    # @param [Hash] msg_params
    # @return [Hash] A json parse hash.
    def upload_multi_msg(msg_params)
      uri = 'cgi-bin/operate_appmsg?t=ajax-response&sub=create&type=10'\
      "&token=#{@token}&lang=zh_CN"
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/appmsg'\
        '?t=media/appmsg_edit&action=edit&type=10'\
        "&isMul=1&isNew=1&lang=zh_CN&token=#{@token}"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers, cookies: @cookies)
      post_msg_res = resource[uri].post msg_params
      JSON.parse post_msg_res.to_s
    end

    # Preview broadcast news to user.
    # system error: no data_bizuin and data_ticket in cookie
    #
    # @param [Hash] msg_params_with_name
    # @return [Hash] A json parse hash.
    def preview_msg(msg_params_with_name)
      uri = 'cgi-bin/operate_appmsg?sub=preview&t=ajax-appmsg-preview'\
            "&type=10&token=#{@token}&lang=zh_CN"
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit'\
                 "&action=edit&type=10&isMul=0&isNew=1&lang=zh_CN&token=#{@token}",
        host: 'mp.weixin.qq.com',
        x_requested_with: 'XMLHttpRequest'
      }
      resource = RestClient::Resource.new(@home_url, headers: headers, cookies: @cookies)

      res = resource[uri].post msg_params_with_name
      # "ret":"0", "msg":"preview send success!", "appMsgId":"201796045", "fakeid":""
      JSON.parse res.to_s
    end

    # Broadcast news to mp.weixin.qq.com.
    #
    # @param [Hash] msg_params
    # @return [Hash] A json parse hash.
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
      JSON.parse post_msg_res.to_s
    end

    # Get all news.
    #
    # @param [Integer] msg_begin
    # @param [Integer] msg_count
    # @return [Hash] A json parse hash.
    def get_app_msg_list(msg_begin = 0, msg_count = 10)
      url = 'https://mp.weixin.qq.com/cgi-bin/appmsg?type=10&action=list'\
            "&begin=#{msg_begin}&count=#{msg_count}&f=json&token=#{@token}"\
            "&lang=zh_CN&token=#{@token}&lang=zh_CN&f=json&ajax=1"\
            "&random=#{rand}"
      msg_json = RestClient.get url, cookies: @cookies
      JSON.parse msg_json.to_s
    end

    # Get new coming msgs from user.
    #
    # @param [String] last_msg_id
    # @return [Hash] A json parse hash.
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

    # Get user info.
    #
    # @param [String] fakeid
    # @return [Hash] A json parse hash.
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

    # Get country list.
    #
    # @return [Hash] A json parse hash.
    def get_country_list
      url = 'https://mp.weixin.qq.com/cgi-bin/getregions'\
            "?t=setting/ajax-getregions&id=0&token=#{@token}&lang=zh_CN"\
            "&f=json&ajax=1&random=#{rand}"
      resource = RestClient::Resource.new(url, cookies: @cookies)
      res = resource.get
      JSON.parse res.to_s
    end

    # Get this weixin can broadcast news count.
    #
    # @return [Integer] day msg count.
    def get_day_msg_count
      url = 'https://mp.weixin.qq.com/cgi-bin/masssendpage'\
            "?t=mass/send&token=#{@token}&lang=zh_CN"
      res = RestClient.get(url, cookies: @cookies)
      day_msg_count = 0
      reg = /.*mass_send_left\s*:\s*can_verify_apply\s*\?\s*\'(\d*)\'\*/
      day_msg_count = $1 if reg =~ res.to_s
      day_msg_count.to_i
    end

    # Get msg items.
    #
    # @param [Integer] count
    # @param [Integer] day
    # @param [Integer] filterivrmsg
    # @param [String] action
    # @param [String] keyword
    # @param [String] offset
    # @return [Hash] A json parse hash.
    def get_msg_items(count = 20, day = 7, filterivrmsg = 1, action='', keyword='', frommsgid='', offset='')
      url = 'https://mp.weixin.qq.com/cgi-bin/message?t=message/list'\
            "&action=#{action}&keyword=#{keyword}&frommsgid=#{frommsgid}&offset=#{offset}&count=#{count}"\
            "&day=#{day}filterivrmsg=#{filterivrmsg}&token=#{@token}&lang=zh_CN"
      resource = RestClient::Resource.new(url, cookies: @cookies)
      res = resource.get
      reg = /.*total_count\s*:\s*(\d*).*latest_msg_id\s*:\s*\'(\d*)\'.*list\s*:\s*\((.*)\)\.msg_item,.*filterivrmsg\s*:\s*\"(\d*)\".*/m
      return_hash = {
          status: -1,
          msg: 'system_error'
      }
      if reg =~ res.to_s
        res_str = $3
        return_hash = {
          status: 0,
          msg: 'ok',
          total_count: $1,
          latest_msg_id: $2,
          count: 20,
          day: 7,
          frommsgid: '',
          can_search_msg: '1',
          offset: '',
          action: '',
          keyword: '',
          msg_items: JSON.parse(res_str)['msg_item'],
          filterivrmsg: $4
        }
      end
      return_hash
    end

    # Get fans count.
    #
    # @return [Hash] Fans count with friends_list, group_list etc.
    def get_fans_count
      url = 'https://mp.weixin.qq.com/cgi-bin/contactmanage?t=user/index'\
      "&pagesize=10&pageidx=0&type=0&token=#{ @token }&lang=zh_CN"
      res = RestClient.get(url, cookies: @cookies)
      reg = /.*pageIdx\s*:\s*(\d*).*pageCount\s*:\s*(\d*).*pageSize\s*:\s*(\d*).*groupsList\s*:\s*\((.*)\)\.groups,.*friendsList\s*:\s*\((.*)\)\.contacts,.*totalCount\s*:\s*\'(\d*)\'\s*\*\s*.*/m
      return_hash = {
        status: -1,
        msg: 'system_error'
      }
      if reg =~ res.to_s
        return_hash = {
          status: 0,
          msg: 'ok',
          page_index: $1,
          page_count: $2,
          page_size: $3,
          group_list: JSON.parse($4)['groups'],
          friends_list: JSON.parse($5)['contacts'],
          total_count: $6
        }
      end
      return_hash
    end

    # Quick reply to user.
    #
    # @param [String] content
    # @param [String] quickreplyid
    # @param [String] tofakeid
    # @return [Hash] A json parse hash.
    def quick_reply(content, quickreplyid, tofakeid)
      post_uri = 'cgi-bin/singlesend'\
                 "?t=ajax-response&f=json&token=#{ @token }&lang=zh_CN"
      params = {
        ajax: 1,
        content: content,
        f: 'json',
        imgcode: '',
        lang: 'zh_CN',
        mask: false,
        quickreplyid: quickreplyid,
        random: rand,
        tofakeid: tofakeid,
        token: @token,
        type: 1
      }
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/message'\
                 "?t=message/list&count=20&day=7&token=#{ @token }&lang=zh_CN"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers,
                                          cookies: @cookies)
      res = resource[post_uri].post params
      #
      # 10706: "customer block" => "48小时内的才行"
      JSON.parse res.to_s
    end

    # Collect msg of user.
    #
    # @param [String] msgid
    # @return [Hash] A json parse hash.
    def collect_msg(msgid)
      uri = "cgi-bin/setstarmessage?t=ajax-setstarmessage&token=#{ @token }&lang=zh_CN"
      params = {
        ajax: 1,
        f: 'json',
        lang: 'zh_CN',
        msgid: msgid,
        random: rand,
        token: @token,
        value: 1
      }
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/message'\
                 "?t=message/list&token=#{ @token }&count=20&day=7"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers,
                                          cookies: @cookies)
      res = resource[uri].post params
      JSON.parse res.to_s
    end

    # Un collect msg of user.
    #
    # @param [String] msgid
    # @return [Hash] A json parse hash.
    def un_collect_msg(msgid)
      uri = "cgi-bin/setstarmessage?t=ajax-setstarmessage&token=#{ @token }&lang=zh_CN"
      params = {
        ajax: 1,
        f: 'json',
        lang: 'zh_CN',
        msgid: msgid,
        random: rand,
        token: @token,
        value: 0
      }
      headers = {
        referer: 'https://mp.weixin.qq.com/cgi-bin/message'\
                 "?t=message/list&token=#{ @token }&count=20&day=7"
      }
      resource = RestClient::Resource.new(@home_url, headers: headers,
                                          cookies: @cookies)
      res = resource[uri].post params
      JSON.parse res.to_s
    end

    private

    def decode_cookies(cookies)
      need_decode = [
        'data_bizuin',
        'data_ticket',
        'slave_user',
        'slave_sid',
        'bizuin'
      ]
      cookies.each do |key, val|
        if need_decode.include?(key)
          cookies[key] = URI.unescape(cookies[val])
        end
      end
      cookies
    end

    def qq_emoji
      {
          "☀" => "2600",
          "☁" => "2601",
          "☔" => "2614",
          "⛄" => "26c4",
          "⚡" => "26a1",
          "🌀" => "1f300",
          "🌁" => "1f301",
          "🌂" => "1f302",
          "🌃" => "1f303",
          "🌄" => "1f304",
          "🌅" => "1f305",
          "🌆" => "1f306",
          "🌇" => "1f307",
          "🌈" => "1f308",
          "❄" => "2744",
          "⛅" => "26c5",
          "🌉" => "1f309",
          "🌊" => "1f30a",
          "🌋" => "1f30b",
          "🌌" => "1f30c",
          "🌏" => "1f30f",
          "🌑" => "1f311",
          "🌔" => "1f314",
          "🌓" => "1f313",
          "🌙" => "1f319",
          "🌕" => "1f315",
          "🌛" => "1f31b",
          "🌟" => "1f31f",
          "🌠" => "1f320",
          "🕐" => "1f550",
          "🕑" => "1f551",
          "🕒" => "1f552",
          "🕓" => "1f553",
          "🕔" => "1f554",
          "🕕" => "1f555",
          "🕖" => "1f556",
          "🕗" => "1f557",
          "🕘" => "1f558",
          "🕙" => "1f559",
          "🕚" => "1f55a",
          "🕛" => "1f55b",
          "⌚" => "231a",
          "⌛" => "231b",
          "⏰" => "23f0",
          "⏳" => "23f3",
          "♈" => "2648",
          "♉" => "2649",
          "♊" => "264a",
          "♋" => "264b",
          "♌" => "264c",
          "♍" => "264d",
          "♎" => "264e",
          "♏" => "264f",
          "♐" => "2650",
          "♑" => "2651",
          "♒" => "2652",
          "♓" => "2653",
          "⛎" => "26ce",
          "🍀" => "1f340",
          "🌷" => "1f337",
          "🌱" => "1f331",
          "🍁" => "1f341",
          "🌸" => "1f338",
          "🌹" => "1f339",
          "🍂" => "1f342",
          "🍃" => "1f343",
          "🌺" => "1f33a",
          "🌻" => "1f33b",
          "🌴" => "1f334",
          "🌵" => "1f335",
          "🌾" => "1f33e",
          "🌽" => "1f33d",
          "🍄" => "1f344",
          "🌰" => "1f330",
          "🌼" => "1f33c",
          "🌿" => "1f33f",
          "🍒" => "1f352",
          "🍌" => "1f34c",
          "🍎" => "1f34e",
          "🍊" => "1f34a",
          "🍓" => "1f353",
          "🍉" => "1f349",
          "🍅" => "1f345",
          "🍆" => "1f346",
          "🍈" => "1f348",
          "🍍" => "1f34d",
          "🍇" => "1f347",
          "🍑" => "1f351",
          "🍏" => "1f34f",
          "👀" => "1f440",
          "👂" => "1f442",
          "👃" => "1f443",
          "👄" => "1f444",
          "👅" => "1f445",
          "💄" => "1f484",
          "💅" => "1f485",
          "💆" => "1f486",
          "💇" => "1f487",
          "💈" => "1f488",
          "👤" => "1f464",
          "👦" => "1f466",
          "👧" => "1f467",
          "👨" => "1f468",
          "👩" => "1f469",
          "👪" => "1f46a",
          "👫" => "1f46b",
          "👮" => "1f46e",
          "👯" => "1f46f",
          "👰" => "1f470",
          "👱" => "1f471",
          "👲" => "1f472",
          "👳" => "1f473",
          "👴" => "1f474",
          "👵" => "1f475",
          "👶" => "1f476",
          "👷" => "1f477",
          "👸" => "1f478",
          "👹" => "1f479",
          "👺" => "1f47a",
          "👻" => "1f47b",
          "👼" => "1f47c",
          "👽" => "1f47d",
          "👾" => "1f47e",
          "👿" => "1f47f",
          "💀" => "1f480",
          "💁" => "1f481",
          "💂" => "1f482",
          "💃" => "1f483",
          "🐌" => "1f40c",
          "🐍" => "1f40d",
          "🐎" => "1f40e",
          "🐔" => "1f414",
          "🐗" => "1f417",
          "🐫" => "1f42b",
          "🐘" => "1f418",
          "🐨" => "1f428",
          "🐒" => "1f412",
          "🐑" => "1f411",
          "🐙" => "1f419",
          "🐚" => "1f41a",
          "🐛" => "1f41b",
          "🐜" => "1f41c",
          "🐝" => "1f41d",
          "🐞" => "1f41e",
          "🐠" => "1f420",
          "🐡" => "1f421",
          "🐢" => "1f422",
          "🐤" => "1f424",
          "🐥" => "1f425",
          "🐦" => "1f426",
          "🐣" => "1f423",
          "🐧" => "1f427",
          "🐩" => "1f429",
          "🐟" => "1f41f",
          "🐬" => "1f42c",
          "🐭" => "1f42d",
          "🐯" => "1f42f",
          "🐱" => "1f431",
          "🐳" => "1f433",
          "🐴" => "1f434",
          "🐵" => "1f435",
          "🐶" => "1f436",
          "🐷" => "1f437",
          "🐻" => "1f43b",
          "🐹" => "1f439",
          "🐺" => "1f43a",
          "🐮" => "1f42e",
          "🐰" => "1f430",
          "🐸" => "1f438",
          "🐾" => "1f43e",
          "🐲" => "1f432",
          "🐼" => "1f43c",
          "🐽" => "1f43d",
          "😠" => "1f620",
          "😩" => "1f629",
          "😲" => "1f632",
          "😞" => "1f61e",
          "😵" => "1f635",
          "😰" => "1f630",
          "😒" => "1f612",
          "😍" => "1f60d",
          "😤" => "1f624",
          "😜" => "1f61c",
          "😝" => "1f61d",
          "😋" => "1f60b",
          "😘" => "1f618",
          "😚" => "1f61a",
          "😷" => "1f637",
          "😳" => "1f633",
          "😃" => "1f603",
          "😅" => "1f605",
          "😆" => "1f606",
          "😁" => "1f601",
          "😂" => "1f602",
          "😊" => "1f60a",
          "☺" => "263a",
          "😄" => "1f604",
          "😢" => "1f622",
          "😭" => "1f62d",
          "😨" => "1f628",
          "😣" => "1f623",
          "😡" => "1f621",
          "😌" => "1f60c",
          "😖" => "1f616",
          "😔" => "1f614",
          "😱" => "1f631",
          "😪" => "1f62a",
          "😏" => "1f60f",
          "😓" => "1f613",
          "😥" => "1f625",
          "😫" => "1f62b",
          "😉" => "1f609",
          "😺" => "1f63a",
          "😸" => "1f638",
          "😹" => "1f639",
          "😽" => "1f63d",
          "😻" => "1f63b",
          "😿" => "1f63f",
          "😾" => "1f63e",
          "😼" => "1f63c",
          "🙀" => "1f640",
          "🙅" => "1f645",
          "🙆" => "1f646",
          "🙇" => "1f647",
          "🙈" => "1f648",
          "🙊" => "1f64a",
          "🙉" => "1f649",
          "🙋" => "1f64b",
          "🙌" => "1f64c",
          "🙍" => "1f64d",
          "🙎" => "1f64e",
          "🙏" => "1f64f",
          "🏠" => "1f3e0",
          "🏡" => "1f3e1",
          "🏢" => "1f3e2",
          "🏣" => "1f3e3",
          "🏥" => "1f3e5",
          "🏦" => "1f3e6",
          "🏧" => "1f3e7",
          "🏨" => "1f3e8",
          "🏩" => "1f3e9",
          "🏪" => "1f3ea",
          "🏫" => "1f3eb",
          "⛪" => "26ea",
          "⛲" => "26f2",
          "🏬" => "1f3ec",
          "🏯" => "1f3ef",
          "🏰" => "1f3f0",
          "🏭" => "1f3ed",
          "⚓" => "2693",
          "🏮" => "1f3ee",
          "🗻" => "1f5fb",
          "🗼" => "1f5fc",
          "🗽" => "1f5fd",
          "🗾" => "1f5fe",
          "🗿" => "1f5ff",
          "👞" => "1f45e",
          "👟" => "1f45f",
          "👠" => "1f460",
          "👡" => "1f461",
          "👢" => "1f462",
          "👣" => "1f463",
          "👓" => "1f453",
          "👕" => "1f455",
          "👖" => "1f456",
          "👑" => "1f451",
          "👔" => "1f454",
          "👒" => "1f452",
          "👗" => "1f457",
          "👘" => "1f458",
          "👙" => "1f459",
          "👚" => "1f45a",
          "👛" => "1f45b",
          "👜" => "1f45c",
          "👝" => "1f45d",
          "💰" => "1f4b0",
          "💱" => "1f4b1",
          "💹" => "1f4b9",
          "💲" => "1f4b2",
          "💳" => "1f4b3",
          "💴" => "1f4b4",
          "💵" => "1f4b5",
          "💸" => "1f4b8",
          "🇨🇳" => "1f1e81f1f3",
          "🇩🇪" => "1f1e91f1ea",
          "🇪🇸" => "1f1ea1f1f8",
          "🇫🇷" => "1f1eb1f1f7",
          "🇬🇧" => "1f1ec1f1e7",
          "🇮🇹" => "1f1ee1f1f9",
          "🇯🇵" => "1f1ef1f1f5",
          "🇰🇷" => "1f1f01f1f7",
          "🇷🇺" => "1f1f71f1fa",
          "🇺🇸" => "1f1fa1f1f8",
          "🔥" => "1f525",
          "🔦" => "1f526",
          "🔧" => "1f527",
          "🔨" => "1f528",
          "🔩" => "1f529",
          "🔪" => "1f52a",
          "🔫" => "1f52b",
          "🔮" => "1f52e",
          "🔯" => "1f52f",
          "🔰" => "1f530",
          "🔱" => "1f531",
          "💉" => "1f489",
          "💊" => "1f48a",
          "🅰" => "1f170",
          "🅱" => "1f171",
          "🆎" => "1f18e",
          "🅾" => "1f17e",
          "🎀" => "1f380",
          "🎁" => "1f381",
          "🎂" => "1f382",
          "🎄" => "1f384",
          "🎅" => "1f385",
          "🎌" => "1f38c",
          "🎆" => "1f386",
          "🎈" => "1f388",
          "🎉" => "1f389",
          "🎍" => "1f38d",
          "🎎" => "1f38e",
          "🎓" => "1f393",
          "🎒" => "1f392",
          "🎏" => "1f38f",
          "🎇" => "1f387",
          "🎐" => "1f390",
          "🎃" => "1f383",
          "🎊" => "1f38a",
          "🎋" => "1f38b",
          "🎑" => "1f391",
          "📟" => "1f4df",
          "☎" => "260e",
          "📞" => "1f4de",
          "📱" => "1f4f1",
          "📲" => "1f4f2",
          "📝" => "1f4dd",
          "📠" => "1f4e0",
          "✉" => "2709",
          "📨" => "1f4e8",
          "📩" => "1f4e9",
          "📪" => "1f4ea",
          "📫" => "1f4eb",
          "📮" => "1f4ee",
          "📰" => "1f4f0",
          "📢" => "1f4e2",
          "📣" => "1f4e3",
          "📡" => "1f4e1",
          "📤" => "1f4e4",
          "📥" => "1f4e5",
          "📦" => "1f4e6",
          "📧" => "1f4e7",
          "🔠" => "1f520",
          "🔡" => "1f521",
          "🔢" => "1f522",
          "🔣" => "1f523",
          "🔤" => "1f524",
          "✒" => "2712",
          "💺" => "1f4ba",
          "💻" => "1f4bb",
          "✏" => "270f",
          "📎" => "1f4ce",
          "💼" => "1f4bc",
          "💽" => "1f4bd",
          "💾" => "1f4be",
          "💿" => "1f4bf",
          "📀" => "1f4c0",
          "✂" => "2702",
          "📍" => "1f4cd",
          "📃" => "1f4c3",
          "📄" => "1f4c4",
          "📅" => "1f4c5",
          "📁" => "1f4c1",
          "📂" => "1f4c2",
          "📓" => "1f4d3",
          "📖" => "1f4d6",
          "📔" => "1f4d4",
          "📕" => "1f4d5",
          "📗" => "1f4d7",
          "📘" => "1f4d8",
          "📙" => "1f4d9",
          "📚" => "1f4da",
          "📛" => "1f4db",
          "📜" => "1f4dc",
          "📋" => "1f4cb",
          "📆" => "1f4c6",
          "📊" => "1f4ca",
          "📈" => "1f4c8",
          "📉" => "1f4c9",
          "📇" => "1f4c7",
          "📌" => "1f4cc",
          "📒" => "1f4d2",
          "📏" => "1f4cf",
          "📐" => "1f4d0",
          "📑" => "1f4d1",
          "🎽" => "1f3bd",
          "⚾" => "26be",
          "⛳" => "26f3",
          "🎾" => "1f3be",
          "⚽" => "26bd",
          "🎿" => "1f3bf",
          "🏀" => "1f3c0",
          "🏁" => "1f3c1",
          "🏂" => "1f3c2",
          "🏃" => "1f3c3",
          "🏄" => "1f3c4",
          "🏆" => "1f3c6",
          "🏈" => "1f3c8",
          "🏊" => "1f3ca",
          "🚃" => "1f683",
          "🚇" => "1f687",
          "Ⓜ" => "24c2",
          "🚄" => "1f684",
          "🚅" => "1f685",
          "🚗" => "1f697",
          "🚙" => "1f699",
          "🚌" => "1f68c",
          "🚏" => "1f68f",
          "🚢" => "1f6a2",
          "✈" => "2708",
          "⛵" => "26f5",
          "🚉" => "1f689",
          "🚀" => "1f680",
          "🚤" => "1f6a4",
          "🚕" => "1f695",
          "🚚" => "1f69a",
          "🚒" => "1f692",
          "🚑" => "1f691",
          "🚓" => "1f693",
          "⛽" => "26fd",
          "🅿" => "1f17f",
          "🚥" => "1f6a5",
          "🚧" => "1f6a7",
          "🚨" => "1f6a8",
          "♨" => "2668",
          "⛺" => "26fa",
          "🎠" => "1f3a0",
          "🎡" => "1f3a1",
          "🎢" => "1f3a2",
          "🎣" => "1f3a3",
          "🎤" => "1f3a4",
          "🎥" => "1f3a5",
          "🎦" => "1f3a6",
          "🎧" => "1f3a7",
          "🎨" => "1f3a8",
          "🎩" => "1f3a9",
          "🎪" => "1f3aa",
          "🎫" => "1f3ab",
          "🎬" => "1f3ac",
          "🎭" => "1f3ad",
          "🎮" => "1f3ae",
          "🀄" => "1f004",
          "🎯" => "1f3af",
          "🎰" => "1f3b0",
          "🎱" => "1f3b1",
          "🎲" => "1f3b2",
          "🎳" => "1f3b3",
          "🎴" => "1f3b4",
          "🃏" => "1f0cf",
          "🎵" => "1f3b5",
          "🎶" => "1f3b6",
          "🎷" => "1f3b7",
          "🎸" => "1f3b8",
          "🎹" => "1f3b9",
          "🎺" => "1f3ba",
          "🎻" => "1f3bb",
          "🎼" => "1f3bc",
          "〽" => "303d",
          "📷" => "1f4f7",
          "📹" => "1f4f9",
          "📺" => "1f4fa",
          "📻" => "1f4fb",
          "📼" => "1f4fc",
          "💋" => "1f48b",
          "💌" => "1f48c",
          "💍" => "1f48d",
          "💎" => "1f48e",
          "💏" => "1f48f",
          "💐" => "1f490",
          "💑" => "1f491",
          "💒" => "1f492",
          "🔞" => "1f51e",
          "©" => "a9",
          "®" => "ae",
          "™" => "2122",
          "ℹ" => "2139",
          "#⃣" => "2320e3",
          "1⃣" => "3120e3",
          "2⃣" => "3220e3",
          "3⃣" => "3320e3",
          "4⃣" => "3420e3",
          "5⃣" => "3520e3",
          "6⃣" => "3620e3",
          "7⃣" => "3720e3",
          "8⃣" => "3820e3",
          "9⃣" => "3920e3",
          "0⃣" => "3020e3",
          "🔟" => "1f51f",
          "📶" => "1f4f6",
          "📳" => "1f4f3",
          "📴" => "1f4f4",
          "🍔" => "1f354",
          "🍙" => "1f359",
          "🍰" => "1f370",
          "🍜" => "1f35c",
          "🍞" => "1f35e",
          "🍳" => "1f373",
          "🍦" => "1f366",
          "🍟" => "1f35f",
          "🍡" => "1f361",
          "🍘" => "1f358",
          "🍚" => "1f35a",
          "🍝" => "1f35d",
          "🍛" => "1f35b",
          "🍢" => "1f362",
          "🍣" => "1f363",
          "🍱" => "1f371",
          "🍲" => "1f372",
          "🍧" => "1f367",
          "🍖" => "1f356",
          "🍥" => "1f365",
          "🍠" => "1f360",
          "🍕" => "1f355",
          "🍗" => "1f357",
          "🍨" => "1f368",
          "🍩" => "1f369",
          "🍪" => "1f36a",
          "🍫" => "1f36b",
          "🍬" => "1f36c",
          "🍭" => "1f36d",
          "🍮" => "1f36e",
          "🍯" => "1f36f",
          "🍤" => "1f364",
          "🍴" => "1f374",
          "☕" => "2615",
          "🍸" => "1f378",
          "🍺" => "1f37a",
          "🍵" => "1f375",
          "🍶" => "1f376",
          "🍷" => "1f377",
          "🍻" => "1f37b",
          "🍹" => "1f379",
          "↗" => "2197",
          "↘" => "2198",
          "↖" => "2196",
          "↙" => "2199",
          "⤴" => "2934",
          "⤵" => "2935",
          "↔" => "2194",
          "↕" => "2195",
          "⬆" => "2b06",
          "⬇" => "2b07",
          "➡" => "27a1",
          "⬅" => "2b05",
          "▶" => "25b6",
          "◀" => "25c0",
          "⏩" => "23e9",
          "⏪" => "23ea",
          "⏫" => "23eb",
          "⏬" => "23ec",
          "🔺" => "1f53a",
          "🔻" => "1f53b",
          "🔼" => "1f53c",
          "🔽" => "1f53d",
          "⭕" => "2b55",
          "❌" => "274c",
          "❎" => "274e",
          "❗" => "2757",
          "⁉" => "2049",
          "‼" => "203c",
          "❓" => "2753",
          "❔" => "2754",
          "❕" => "2755",
          "〰" => "3030",
          "➰" => "27b0",
          "➿" => "27bf",
          "❤" => "2764",
          "💓" => "1f493",
          "💔" => "1f494",
          "💕" => "1f495",
          "💖" => "1f496",
          "💗" => "1f497",
          "💘" => "1f498",
          "💙" => "1f499",
          "💚" => "1f49a",
          "💛" => "1f49b",
          "💜" => "1f49c",
          "💝" => "1f49d",
          "💞" => "1f49e",
          "💟" => "1f49f",
          "♥" => "2665",
          "♠" => "2660",
          "♦" => "2666",
          "♣" => "2663",
          "🚬" => "1f6ac",
          "🚭" => "1f6ad",
          "♿" => "267f",
          "🚩" => "1f6a9",
          "⚠" => "26a0",
          "⛔" => "26d4",
          "♻" => "267b",
          "🚲" => "1f6b2",
          "🚶" => "1f6b6",
          "🚹" => "1f6b9",
          "🚺" => "1f6ba",
          "🛀" => "1f6c0",
          "🚻" => "1f6bb",
          "🚽" => "1f6bd",
          "🚾" => "1f6be",
          "🚼" => "1f6bc",
          "🚪" => "1f6aa",
          "🚫" => "1f6ab",
          "✔" => "2714",
          "🆑" => "1f191",
          "🆒" => "1f192",
          "🆓" => "1f193",
          "🆔" => "1f194",
          "🆕" => "1f195",
          "🆖" => "1f196",
          "🆗" => "1f197",
          "🆘" => "1f198",
          "🆙" => "1f199",
          "🆚" => "1f19a",
          "🈁" => "1f201",
          "🈂" => "1f202",
          "🈲" => "1f232",
          "🈳" => "1f233",
          "🈴" => "1f234",
          "🈵" => "1f235",
          "🈶" => "1f236",
          "🈚" => "1f21a",
          "🈷" => "1f237",
          "🈸" => "1f238",
          "🈹" => "1f239",
          "🈯" => "1f22f",
          "🈺" => "1f23a",
          "㊙" => "3299",
          "㊗" => "3297",
          "🉐" => "1f250",
          "🉑" => "1f251",
          "➕" => "2795",
          "➖" => "2796",
          "✖" => "2716",
          "➗" => "2797",
          "💠" => "1f4a0",
          "💡" => "1f4a1",
          "💢" => "1f4a2",
          "💣" => "1f4a3",
          "💤" => "1f4a4",
          "💥" => "1f4a5",
          "💦" => "1f4a6",
          "💧" => "1f4a7",
          "💨" => "1f4a8",
          "💩" => "1f4a9",
          "💪" => "1f4aa",
          "💫" => "1f4ab",
          "💬" => "1f4ac",
          "✨" => "2728",
          "✴" => "2734",
          "✳" => "2733",
          "⚪" => "26aa",
          "⚫" => "26ab",
          "🔴" => "1f534",
          "🔵" => "1f535",
          "🔲" => "1f532",
          "🔳" => "1f533",
          "⭐" => "2b50",
          "⬜" => "2b1c",
          "⬛" => "2b1b",
          "▫" => "25ab",
          "▪" => "25aa",
          "◽" => "25fd",
          "◾" => "25fe",
          "◻" => "25fb",
          "◼" => "25fc",
          "🔶" => "1f536",
          "🔷" => "1f537",
          "🔸" => "1f538",
          "🔹" => "1f539",
          "❇" => "2747",
          "💮" => "1f4ae",
          "💯" => "1f4af",
          "↩" => "21a9",
          "↪" => "21aa",
          "🔃" => "1f503",
          "🔊" => "1f50a",
          "🔋" => "1f50b",
          "🔌" => "1f50c",
          "🔍" => "1f50d",
          "🔎" => "1f50e",
          "🔒" => "1f512",
          "🔓" => "1f513",
          "🔏" => "1f50f",
          "🔐" => "1f510",
          "🔑" => "1f511",
          "🔔" => "1f514",
          "☑" => "2611",
          "🔘" => "1f518",
          "🔖" => "1f516",
          "🔗" => "1f517",
          "🔙" => "1f519",
          "🔚" => "1f51a",
          "🔛" => "1f51b",
          "🔜" => "1f51c",
          "🔝" => "1f51d",
          " " => "2003",
          " " => "2002",
          " " => "2005",
          "✅" => "2705",
          "✊" => "270a",
          "✋" => "270b",
          "✌" => "270c",
          "👊" => "1f44a",
          "👍" => "1f44d",
          "☝" => "261d",
          "👆" => "1f446",
          "👇" => "1f447",
          "👈" => "1f448",
          "👉" => "1f449",
          "👋" => "1f44b",
          "👏" => "1f44f",
          "👌" => "1f44c",
          "👎" => "1f44e",
          "👐" => "1f450",
          "" => "2600",
          "" => "2601",
          "" => "2614",
          "" => "26c4",
          "" => "26a1",
          "" => "1f300",
          "[霧]" => "1f301",
          "" => "1f302",
          "" => "1f30c",
          "" => "1f304",
          "" => "1f305",
          "" => "1f306",
          "" => "1f307",
          "" => "1f308",
          "[雪結晶]" => "2744",
          "" => "26c5",
          "" => "1f30a",
          "[火山]" => "1f30b",
          "[地球]" => "1f30f",
          "●" => "1f311",
          "" => "1f31b",
          "○" => "1f315",
          "" => "1f31f",
          "☆彡" => "1f320",
          "" => "1f550",
          "" => "1f551",
          "" => "1f552",
          "" => "1f553",
          "" => "1f554",
          "" => "1f555",
          "" => "1f556",
          "" => "1f557",
          "" => "1f558",
          "" => "23f0",
          "" => "1f55a",
          "" => "1f55b",
          "[腕時計]" => "231a",
          "[砂時計]" => "23f3",
          "" => "2648",
          "" => "2649",
          "" => "264a",
          "" => "264b",
          "" => "264c",
          "" => "264d",
          "" => "264e",
          "" => "264f",
          "" => "2650",
          "" => "2651",
          "" => "2652",
          "" => "2653",
          "" => "26ce",
          "" => "1f33f",
          "" => "1f337",
          "" => "1f341",
          "" => "1f338",
          "" => "1f339",
          "" => "1f342",
          "" => "1f343",
          "" => "1f33a",
          "" => "1f33c",
          "" => "1f334",
          "" => "1f335",
          "" => "1f33e",
          "[とうもろこし]" => "1f33d",
          "[キノコ]" => "1f344",
          "[栗]" => "1f330",
          "[さくらんぼ]" => "1f352",
          "[バナナ]" => "1f34c",
          "" => "1f34f",
          "" => "1f34a",
          "" => "1f353",
          "" => "1f349",
          "" => "1f345",
          "" => "1f346",
          "[メロン]" => "1f348",
          "[パイナップル]" => "1f34d",
          "[ブドウ]" => "1f347",
          "[モモ]" => "1f351",
          "" => "1f440",
          "" => "1f442",
          "" => "1f443",
          "" => "1f444",
          "" => "1f61d",
          "" => "1f484",
          "" => "1f485",
          "" => "1f486",
          "" => "1f487",
          "" => "1f488",
          "〓" => "2005",
          "" => "1f466",
          "" => "1f467",
          "" => "1f468",
          "" => "1f469",
          "[家族]" => "1f46a",
          "" => "1f46b",
          "" => "1f46e",
          "" => "1f46f",
          "[花嫁]" => "1f470",
          "" => "1f471",
          "" => "1f472",
          "" => "1f473",
          "" => "1f474",
          "" => "1f475",
          "" => "1f476",
          "" => "1f477",
          "" => "1f478",
          "[なまはげ]" => "1f479",
          "[天狗]" => "1f47a",
          "" => "1f47b",
          "" => "1f47c",
          "" => "1f47d",
          "" => "1f47e",
          "" => "1f47f",
          "" => "1f480",
          "" => "1f481",
          "" => "1f482",
          "" => "1f483",
          "[カタツムリ]" => "1f40c",
          "" => "1f40d",
          "" => "1f40e",
          "" => "1f414",
          "" => "1f417",
          "" => "1f42b",
          "" => "1f418",
          "" => "1f428",
          "" => "1f412",
          "" => "1f411",
          "" => "1f419",
          "" => "1f41a",
          "" => "1f41b",
          "[アリ]" => "1f41c",
          "[ミツバチ]" => "1f41d",
          "[てんとう虫]" => "1f41e",
          "" => "1f420",
          "" => "1f3a3",
          "[カメ]" => "1f422",
          "" => "1f423",
          "" => "1f426",
          "" => "1f427",
          "" => "1f436",
          "" => "1f42c",
          "" => "1f42d",
          "" => "1f42f",
          "" => "1f431",
          "" => "1f433",
          "" => "1f434",
          "" => "1f435",
          "" => "1f43d",
          "" => "1f43b",
          "" => "1f439",
          "" => "1f43a",
          "" => "1f42e",
          "" => "1f430",
          "" => "1f438",
          "" => "1f463",
          "[辰]" => "1f432",
          "[パンダ]" => "1f43c",
          "" => "1f620",
          "" => "1f64d",
          "" => "1f632",
          "" => "1f61e",
          "" => "1f62b",
          "" => "1f630",
          "" => "1f612",
          "" => "1f63b",
          "" => "1f63c",
          "" => "1f61c",
          "" => "1f60a",
          "" => "1f63d",
          "" => "1f61a",
          "" => "1f637",
          "" => "1f633",
          "" => "1f63a",
          "" => "1f605",
          "" => "1f60c",
          "" => "1f639",
          "" => "263a",
          "" => "1f604",
          "" => "1f63f",
          "" => "1f62d",
          "" => "1f628",
          "" => "1f64e",
          "" => "1f4ab",
          "" => "1f631",
          "" => "1f62a",
          "" => "1f60f",
          "" => "1f613",
          "" => "1f625",
          "" => "1f609",
          "" => "1f645",
          "" => "1f646",
          "" => "1f647",
          "(/_＼)" => "1f648",
          "(・×・)" => "1f64a",
          "|(・×・)|" => "1f649",
          "" => "270b",
          "" => "1f64c",
          "" => "1f64f",
          "" => "1f3e1",
          "" => "1f3e2",
          "" => "1f3e3",
          "" => "1f3e5",
          "" => "1f3e6",
          "" => "1f3e7",
          "" => "1f3e8",
          "" => "1f3e9",
          "" => "1f3ea",
          "" => "1f3eb",
          "" => "26ea",
          "" => "26f2",
          "" => "1f3ec",
          "" => "1f3ef",
          "" => "1f3f0",
          "" => "1f3ed",
          "" => "1f6a2",
          "" => "1f376",
          "" => "1f5fb",
          "" => "1f5fc",
          "" => "1f5fd",
          "[日本地図]" => "1f5fe",
          "[モアイ]" => "1f5ff",
          "" => "1f45f",
          "" => "1f460",
          "" => "1f461",
          "" => "1f462",
          "[メガネ]" => "1f453",
          "" => "1f45a",
          "[ジーンズ]" => "1f456",
          "" => "1f451",
          "" => "1f454",
          "" => "1f452",
          "" => "1f457",
          "" => "1f458",
          "" => "1f459",
          "[財布]" => "1f45b",
          "" => "1f45c",
          "[ふくろ]" => "1f45d",
          "" => "1f4b5",
          "" => "1f4b1",
          "" => "1f4c8",
          "[カード]" => "1f4b3",
          "￥" => "1f4b4",
          "[飛んでいくお金]" => "1f4b8",
          "" => "1f1e81f1f3",
          "" => "1f1e91f1ea",
          "" => "1f1ea1f1f8",
          "" => "1f1eb1f1f7",
          "" => "1f1ec1f1e7",
          "" => "1f1ee1f1f9",
          "" => "1f1ef1f1f5",
          "" => "1f1f01f1f7",
          "" => "1f1f71f1fa",
          "" => "1f1fa1f1f8",
          "" => "1f525",
          "[懐中電灯]" => "1f526",
          "[レンチ]" => "1f527",
          "" => "1f528",
          "[ネジ]" => "1f529",
          "[包丁]" => "1f52a",
          "" => "1f52b",
          "" => "1f52f",
          "" => "1f530",
          "" => "1f531",
          "" => "1f489",
          "" => "1f48a",
          "" => "1f170",
          "" => "1f171",
          "" => "1f18e",
          "" => "1f17e",
          "" => "1f380",
          "" => "1f4e6",
          "" => "1f382",
          "" => "1f384",
          "" => "1f385",
          "" => "1f38c",
          "" => "1f386",
          "" => "1f388",
          "" => "1f389",
          "" => "1f38d",
          "" => "1f38e",
          "" => "1f393",
          "" => "1f392",
          "" => "1f38f",
          "" => "1f387",
          "" => "1f390",
          "" => "1f383",
          "[オメデトウ]" => "1f38a",
          "[七夕]" => "1f38b",
          "" => "1f391",
          "[ポケベル]" => "1f4df",
          "" => "1f4de",
          "" => "1f4f1",
          "" => "1f4f2",
          "" => "1f4d1",
          "" => "1f4e0",
          "" => "1f4e7",
          "" => "1f4eb",
          "" => "1f4ee",
          "[新聞]" => "1f4f0",
          "" => "1f4e2",
          "" => "1f4e3",
          "" => "1f4e1",
          "[送信BOX]" => "1f4e4",
          "[受信BOX]" => "1f4e5",
          "[ABCD]" => "1f520",
          "[abcd]" => "1f521",
          "[1234]" => "1f522",
          "[記号]" => "1f523",
          "[ABC]" => "1f524",
          "[ペン]" => "2712",
          "" => "1f4ba",
          "" => "1f4bb",
          "[クリップ]" => "1f4ce",
          "" => "1f4bc",
          "" => "1f4be",
          "" => "1f4bf",
          "" => "1f4c0",
          "" => "2702",
          "[画びょう]" => "1f4cc",
          "[カレンダー]" => "1f4c6",
          "[フォルダ]" => "1f4c2",
          "" => "1f4d2",
          "[名札]" => "1f4db",
          "[スクロール]" => "1f4dc",
          "[グラフ]" => "1f4c9",
          "[定規]" => "1f4cf",
          "[三角定規]" => "1f4d0",
          "" => "26be",
          "" => "26f3",
          "" => "1f3be",
          "" => "26bd",
          "" => "1f3bf",
          "" => "1f3c0",
          "" => "1f3c1",
          "[スノボ]" => "1f3c2",
          "" => "1f3c3",
          "" => "1f3c4",
          "" => "1f3c6",
          "" => "1f3c8",
          "" => "1f3ca",
          "" => "1f683",
          "" => "24c2",
          "" => "1f684",
          "" => "1f685",
          "" => "1f697",
          "" => "1f699",
          "" => "1f68c",
          "" => "1f68f",
          "" => "2708",
          "" => "26f5",
          "" => "1f689",
          "" => "1f680",
          "" => "1f6a4",
          "" => "1f695",
          "" => "1f69a",
          "" => "1f692",
          "" => "1f691",
          "" => "1f6a8",
          "" => "26fd",
          "" => "1f17f",
          "" => "1f6a5",
          "" => "26d4",
          "" => "2668",
          "" => "26fa",
          "" => "1f3a1",
          "" => "1f3a2",
          "" => "1f3a4",
          "" => "1f4f9",
          "" => "1f3a6",
          "" => "1f3a7",
          "" => "1f3a8",
          "" => "1f3ad",
          "[イベント]" => "1f3aa",
          "" => "1f3ab",
          "" => "1f3ac",
          "[ゲーム]" => "1f3ae",
          "" => "1f004",
          "" => "1f3af",
          "" => "1f3b0",
          "" => "1f3b1",
          "[サイコロ]" => "1f3b2",
          "[ボーリング]" => "1f3b3",
          "[花札]" => "1f3b4",
          "[ジョーカー]" => "1f0cf",
          "" => "1f3b5",
          "" => "1f3bc",
          "" => "1f3b7",
          "" => "1f3b8",
          "[ピアノ]" => "1f3b9",
          "" => "1f3ba",
          "[バイオリン]" => "1f3bb",
          "" => "303d",
          "" => "1f4f7",
          "" => "1f4fa",
          "" => "1f4fb",
          "" => "1f4fc",
          "" => "1f48b",
          "" => "1f48c",
          "" => "1f48d",
          "" => "1f48e",
          "" => "1f48f",
          "" => "1f490",
          "" => "1f491",
          "" => "1f492",
          "" => "1f51e",
          "" => "a9",
          "" => "ae",
          "" => "2122",
          "[ｉ]" => "2139",
          "" => "2320e3",
          "" => "3120e3",
          "" => "3220e3",
          "" => "3320e3",
          "" => "3420e3",
          "" => "3520e3",
          "" => "3620e3",
          "" => "3720e3",
          "" => "3820e3",
          "" => "3920e3",
          "" => "3020e3",
          "[10]" => "1f51f",
          "" => "1f4f6",
          "" => "1f4f3",
          "" => "1f4f4",
          "" => "1f354",
          "" => "1f359",
          "" => "1f370",
          "" => "1f35c",
          "" => "1f35e",
          "" => "1f373",
          "" => "1f366",
          "" => "1f35f",
          "" => "1f361",
          "" => "1f358",
          "" => "1f35a",
          "" => "1f35d",
          "" => "1f35b",
          "" => "1f362",
          "" => "1f363",
          "" => "1f371",
          "" => "1f372",
          "" => "1f367",
          "[肉]" => "1f356",
          "[なると]" => "1f365",
          "[やきいも]" => "1f360",
          "[ピザ]" => "1f355",
          "[チキン]" => "1f357",
          "[アイスクリーム]" => "1f368",
          "[ドーナツ]" => "1f369",
          "[クッキー]" => "1f36a",
          "[チョコ]" => "1f36b",
          "[キャンディ]" => "1f36d",
          "[プリン]" => "1f36e",
          "[ハチミツ]" => "1f36f",
          "[エビフライ]" => "1f364",
          "" => "1f374",
          "" => "2615",
          "" => "1f379",
          "" => "1f37a",
          "" => "1f375",
          "" => "1f37b",
          "" => "2934",
          "" => "2935",
          "" => "2196",
          "" => "2199",
          "⇔" => "2194",
          "↑↓" => "1f503",
          "" => "2b06",
          "" => "2b07",
          "" => "27a1",
          "" => "1f519",
          "" => "25b6",
          "" => "25c0",
          "" => "23e9",
          "" => "23ea",
          "▲" => "1f53c",
          "▼" => "1f53d",
          "" => "2b55",
          "" => "2716",
          "" => "2757",
          "！？" => "2049",
          "！！" => "203c",
          "" => "2753",
          "" => "2754",
          "" => "2755",
          "～" => "27b0",
          "" => "27bf",
          "" => "2764",
          "" => "1f49e",
          "" => "1f494",
          "" => "1f497",
          "" => "1f498",
          "" => "1f499",
          "" => "1f49a",
          "" => "1f49b",
          "" => "1f49c",
          "" => "1f49d",
          "" => "1f49f",
          "" => "2665",
          "" => "2660",
          "" => "2666",
          "" => "2663",
          "" => "1f6ac",
          "" => "1f6ad",
          "" => "267f",
          "[旗]" => "1f6a9",
          "" => "26a0",
          "" => "1f6b2",
          "" => "1f6b6",
          "" => "1f6b9",
          "" => "1f6ba",
          "" => "1f6c0",
          "" => "1f6bb",
          "" => "1f6bd",
          "" => "1f6be",
          "" => "1f6bc",
          "[ドア]" => "1f6aa",
          "[禁止]" => "1f6ab",
          "[チェックマーク]" => "2705",
          "[CL]" => "1f191",
          "" => "1f192",
          "[FREE]" => "1f193",
          "" => "1f194",
          "" => "1f195",
          "[NG]" => "1f196",
          "" => "1f197",
          "[SOS]" => "1f198",
          "" => "1f199",
          "" => "1f19a",
          "" => "1f201",
          "" => "1f202",
          "[禁]" => "1f232",
          "" => "1f233",
          "[合]" => "1f234",
          "" => "1f235",
          "" => "1f236",
          "" => "1f21a",
          "" => "1f237",
          "" => "1f238",
          "" => "1f239",
          "" => "1f22f",
          "" => "1f23a",
          "" => "3299",
          "" => "3297",
          "" => "1f250",
          "[可]" => "1f251",
          "[＋]" => "2795",
          "[－]" => "2796",
          "[÷]" => "2797",
          "" => "1f4a1",
          "" => "1f4a2",
          "" => "1f4a3",
          "" => "1f4a4",
          "[ドンッ]" => "1f4a5",
          "" => "1f4a7",
          "" => "1f4a8",
          "" => "1f4a9",
          "" => "1f4aa",
          "[フキダシ]" => "1f4ac",
          "" => "2747",
          "" => "2734",
          "" => "2733",
          "" => "1f534",
          "" => "25fc",
          "" => "1f539",
          "" => "2b50",
          "[花丸]" => "1f4ae",
          "[100点]" => "1f4af",
          "←┘" => "21a9",
          "└→" => "21aa",
          "" => "1f50a",
          "[電池]" => "1f50b",
          "[コンセント]" => "1f50c",
          "" => "1f50e",
          "" => "1f510",
          "" => "1f513",
          "" => "1f511",
          "" => "1f514",
          "[ラジオボタン]" => "1f518",
          "[ブックマーク]" => "1f516",
          "[リンク]" => "1f517",
          "[end]" => "1f51a",
          "[ON]" => "1f51b",
          "[SOON]" => "1f51c",
          "" => "1f51d",
          "" => "270a",
          "" => "270c",
          "" => "1f44a",
          "" => "1f44d",
          "" => "261d",
          "" => "1f446",
          "" => "1f447",
          "" => "1f448",
          "" => "1f449",
          "" => "1f44b",
          "" => "1f44f",
          "" => "1f44c",
          "" => "1f44e",
          "" => "1f450",
          "/微笑" => "0",
          "/撇嘴" => "1",
          "/色" => "2",
          "/发呆" => "3",
          "/得意" => "4",
          "/流泪" => "5",
          "/害羞" => "6",
          "/闭嘴" => "7",
          "/睡" => "8",
          "/大哭" => "9",
          "/尴尬" => "10",
          "/发怒" => "11",
          "/调皮" => "12",
          "/呲牙" => "13",
          "/惊讶" => "14",
          "/难过" => "15",
          "/酷" => "16",
          "/冷汗" => "17",
          "/抓狂" => "18",
          "/吐" => "19",
          "/偷笑" => "20",
          "/可爱" => "21",
          "/白眼" => "22",
          "/傲慢" => "23",
          "/饥饿" => "24",
          "/困" => "25",
          "/惊恐" => "26",
          "/流汗" => "27",
          "/憨笑" => "28",
          "/大兵" => "29",
          "/奋斗" => "30",
          "/咒骂" => "31",
          "/疑问" => "32",
          "/嘘" => "33",
          "/晕" => "34",
          "/折磨" => "35",
          "/衰" => "36",
          "/骷髅" => "37",
          "/敲打" => "38",
          "/再见" => "39",
          "/擦汗" => "40",
          "/抠鼻" => "41",
          "/鼓掌" => "42",
          "/糗大了" => "43",
          "/坏笑" => "44",
          "/左哼哼" => "45",
          "/右哼哼" => "46",
          "/哈欠" => "47",
          "/鄙视" => "48",
          "/委屈" => "49",
          "/快哭了" => "50",
          "/阴险" => "51",
          "/亲亲" => "52",
          "/吓" => "53",
          "/可怜" => "54",
          "/菜刀" => "55",
          "/西瓜" => "56",
          "/啤酒" => "57",
          "/篮球" => "58",
          "/乒乓" => "59",
          "/咖啡" => "60",
          "/饭" => "61",
          "/猪头" => "62",
          "/玫瑰" => "63",
          "/凋谢" => "64",
          "/示爱" => "65",
          "/爱心" => "66",
          "/心碎" => "67",
          "/蛋糕" => "68",
          "/闪电" => "69",
          "/炸弹" => "70",
          "/刀" => "71",
          "/足球" => "72",
          "/瓢虫" => "73",
          "/便便" => "74",
          "/月亮" => "75",
          "/太阳" => "76",
          "/礼物" => "77",
          "/拥抱" => "78",
          "/强" => "79",
          "/弱" => "80",
          "/握手" => "81",
          "/胜利" => "82",
          "/抱拳" => "83",
          "/勾引" => "84",
          "/拳头" => "85",
          "/差劲" => "86",
          "/爱你" => "87",
          "/NO" => "88",
          "/OK" => "89",
          "/爱情" => "90",
          "/飞吻" => "91",
          "/跳跳" => "92",
          "/发抖" => "93",
          "/怄火" => "94",
          "/转圈" => "95",
          "/磕头" => "96",
          "/回头" => "97",
          "/跳绳" => "98",
          "/挥手" => "99",
          "/激动" => "100",
          "/街舞" => "101",
          "/献吻" => "102",
          "/左太极" => "103",
          "/右太极" => "104",
          "/::)" => "0",
          "/::~" => "1",
          "/::B" => "2",
          "/::|" => "3",
          "/:8-)" => "4",
          "/::<" => "5",
          "/::$" => "6",
          "/::X" => "7",
          "/::Z" => "8",
          "/::(" => "9",
          "/::'(" => "9",
          "/::-|" => "10",
          "/::@" => "11",
          "/::P" => "12",
          "/::D" => "13",
          "/::O" => "14",
          "/::(" => "15",
          "/::+" => "16",
          "/:--b" => "17",
          "/::Q" => "18",
          "/::T" => "19",
          "/:,@P" => "20",
          "/:,@-D" => "21",
          "/::d" => "22",
          "/:,@o" => "23",
          "/::g" => "24",
          "/:|-)" => "25",
          "/::!" => "26",
          "/::L" => "27",
          "/::>" => "28",
          "/::,@" => "29",
          "/:,@f" => "30",
          "/::-S" => "31",
          "/:?" => "32",
          "/:,@x" => "33",
          "/:,@@" => "34",
          "/::8" => "35",
          "/:,@!" => "36",
          "/:!!!" => "37",
          "/:xx" => "38",
          "/:bye" => "39",
          "/:wipe" => "40",
          "/:dig" => "41",
          "/:handclap" => "42",
          "/:&-(" => "43",
          "/:B-)" => "44",
          "/:<@" => "45",
          "/:@>" => "46",
          "/::-O" => "47",
          "/:>-|" => "48",
          "/:P-(" => "49",
          "/::'|" => "50",
          "/:X-)" => "51",
          "/::*" => "52",
          "/:@x" => "53",
          "/:8*" => "54",
          "/:pd" => "55",
          "/:<W>" => "56",
          "/:beer" => "57",
          "/:basketb" => "58",
          "/:oo" => "59",
          "/:coffee" => "60",
          "/:eat" => "61",
          "/:pig" => "62",
          "/:rose" => "63",
          "/:fade" => "64",
          "/:showlove" => "65",
          "/:heart" => "66",
          "/:break" => "67",
          "/:cake" => "68",
          "/:li" => "69",
          "/:bome" => "70",
          "/:kn" => "71",
          "/:footb" => "72",
          "/:ladybug" => "73",
          "/:shit" => "74",
          "/:moon" => "75",
          "/:sun" => "76",
          "/:gift" => "77",
          "/:hug" => "78",
          "/:strong" => "79",
          "/:weak" => "80",
          "/:share" => "81",
          "/:v" => "82",
          "/:@)" => "83",
          "/:jj" => "84",
          "/:@@" => "85",
          "/:bad" => "86",
          "/:lvu" => "87",
          "/:no" => "88",
          "/:ok" => "89",
          "/:love" => "90",
          "/:<L>" => "91",
          "/:jump" => "92",
          "/:shake" => "93",
          "/:<O>" => "94",
          "/:circle" => "95",
          "/:kotow" => "96",
          "/:turn" => "97",
          "/:skip" => "98",
          "/:oY" => "99",
          "/:#-0" => "100",
          "/:hiphot" => "101",
          "/:kiss" => "102",
          "/:<&" => "103",
          "/:&>" => "104"
      }
    end
  end
end
