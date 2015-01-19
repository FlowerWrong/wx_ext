# encoding: UTF-8

require 'rest_client'

module WxExt
  module Api

    # 微信扩展接口, 模拟登陆微信公众平台
    # @author FuShengYang
    module User
      module Group
        class << self
          def create_group(access_token, group_name)
            url = 'https://api.weixin.qq.com/cgi-bin/groups/create'\
                  "?access_token=#{access_token}"
            Helper.http_post(url, { group: { name: group_name } }.to_json)
          end

          def groups(access_token)
            url = 'https://api.weixin.qq.com/cgi-bin/groups/get'\
                  "?access_token=#{access_token}"
            Helper.http_get(url, { accept: :json })
          end

          def user_of_group(access_token, openid)
            url = 'https://api.weixin.qq.com/cgi-bin/groups/getid'\
                  "?access_token=#{access_token}"
            Helper.http_post(url, { openid: openid })
          end

          def update_group_name(access_token, id, name)
            url = 'https://api.weixin.qq.com/cgi-bin/groups/update'\
                  "?access_token=#{access_token}"
            Helper.http_post(url, { group: { id: id, name: name } })
          end

          def mv_user_group(access_token, openid, to_groupid)
            url = 'https://api.weixin.qq.com/cgi-bin/groups/members/update'\
                  "?access_token=#{access_token}"
            Helper.http_post(url, { openid: openid, to_groupid: to_groupid })
          end
        end
      end
    end
  end
end
