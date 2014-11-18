# encoding: UTF-8
require 'spec_helper'

describe WxExt::WeiXin do
  before(:all) do
    @weixin = WxExt::WeiXin.new 'flowerwrong@hotmail.com', '1*flower@wrong*1'
  end

  it 'init method should init all params' do
    flag = @weixin.init
    if flag
      token = @weixin.token
      puts "token = #{token}"
      expect(token).to match(/\d+/)
    end
  end

  it 'should get day msg count' do
    flag = @weixin.init
    if flag
      day_msg_count = @weixin.get_day_msg_count
      expect(day_msg_count.to_s).to match(/\d*/)
    end
  end

  # 未完待续
  it 'should get fakeids and msg ids' do
    flag = @weixin.init
    res = @weixin.get_ids if flag
    puts res.to_s
  end

  it "should get new msg num" do
    flag = @weixin.init
    res_hash = @weixin.get_new_msg_num('201004139')
    puts res_hash
    expect(res_hash['ret'].to_s).to eql('0')
  end

  it "should get contact info" do
    flag = @weixin.init
    res_hash = @weixin.get_contact_info('204060720')
    puts res_hash
    expect(res_hash['base_resp']['ret'].to_s).to eql('0')
  end

  it "should return a country list" do
    flag = @weixin.init
    res_hash = @weixin.get_country_list
    puts res_hash
    expect(res_hash["num"].to_s).to match(/\d+/)
  end

  it "upload_file method should return a right hash" do
    flag = @weixin.init
    puts @weixin.token
    puts @weixin.ticket_id
    puts @weixin.ticket
    file = File.new("/home/yang/dev/ruby/gem/hack_wx/spec/hack_wx/test_spec.jpg", 'rb')
    file_hash = @weixin.upload_file(file, "test_spec.jpg")
    puts "==" * 20
    puts file_hash
    expect(file_hash["base_resp"]["ret"].to_s).to eql("0")
  end

  it "upload_single_msg method should upload a msg to sucaizhongxin" do
    flag = @weixin.init
    file = File.new("/home/yang/dev/ruby/gem/hack_wx/spec/hack_wx/test_spec.jpg", 'rb')
    file_hash = @weixin.upload_file(file, "test_spec.jpg")
    file_id = file_hash["content"]
    single_msg_params = {
        AppMsgId: '',
        ajax: 1,
        author0: '作者' + rand.to_s,
        content0: '正文' + rand.to_s,
        count: 1,
        digest0: 'test摘要' + rand.to_s,
        f: 'json',
        fileid0: file_id,
        lang: 'zh_CN',
        random: rand,
        show_cover_pic0: 1,
        sourceurl0: 'http://thecampus.cc/' + rand.to_s,
        title0: 'test标题' + rand.to_s,
        token: @weixin.token,
        vid: ''
    }
    msg_hash = @weixin.upload_single_msg(single_msg_params)
    puts "==" * 20
    puts msg_hash
    expect(msg_hash["ret"].to_s).to eql("0")
  end

  it "upload_multi_msg method should upload multi msg to sucaizhongxin" do
    flag = @weixin.init
    file = File.new("/home/yang/dev/ruby/gem/hack_wx/spec/hack_wx/test_spec.jpg", 'rb')
    file_hash = @weixin.upload_file(file, "test_spec.jpg")
    file_id = file_hash["content"]
    msg_params = {
        AppMsgId: '',
        ajax: 1,
        author0: 'test多图文上传作者' + rand.to_s,
        author1: 'test多图文上传作者' + rand.to_s,
        content0: 'test多图文上传正文' + rand.to_s,
        content1: 'test多图文上传正文' + rand.to_s,
        count: 2,
        digest0: 'test多图文上传正文' + rand.to_s,
        digest1: 'test多图文上传正文' + rand.to_s,
        f: 'json',
        fileid0: file_id,
        fileid1: file_id,
        lang: 'zh_CN',
        random: rand,
        show_cover_pic0: 1,
        show_cover_pic1: 1,
        sourceurl0: 'http://thecampus.cc/' + rand.to_s,
        sourceurl1: 'http://thecampus.cc/' + rand.to_s,
        title0: 'test多图文上传标题' + rand.to_s,
        title1: 'test多图文上传标题' + rand.to_s,
        token: @weixin.token,
        vid: ''
    }
    msg_hash = @weixin.upload_multi_msg(msg_params)
    puts "==" * 20
    puts msg_hash
    expect(msg_hash["ret"].to_s).to eql("0")
  end

  it "broadcast msg to all user should return ok" do
    flag = @weixin.init

    msg_hash = @weixin.get_app_msg_list
    puts "==" * 20
    app_msg_id = msg_hash["app_msg_info"]["item"][0]["app_id"]

    msg_params = {
        ajax: 1,
        appmsgid: app_msg_id, # 图文appid
        cardlimit: 1, # 发送限制条数
        city: '',
        country: '',
        province: '',
        f: 'json',
        groupid: '-1',
        imgcode: '',
        lang: 'zh_CN',
        operation_seq: @weixin.operation_seq, #
        random: rand,
        sex: 0,
        synctxweibo: 0,
        token: @weixin.token,
        type: 10
    }
    msg_hash = @weixin.broadcast_msg(msg_params)
    puts "==" * 20
    # {"ret"=>"64004", "msg"=>"not have masssend quota today!"}
    puts msg_hash
    expect(msg_hash["ret"].to_s).to eql("0")
  end

  it "get app msg list return json" do
    flag = @weixin.init

    msg_hash = @weixin.get_app_msg_list
    puts "==" * 20
    puts msg_hash["app_msg_info"]["item"][0]["app_id"]
    expect(msg_hash["base_resp"]["ret"].to_s).to eql("0")
  end
end
