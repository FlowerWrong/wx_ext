# encoding: UTF-8
require 'spec_helper'

describe WxExt::WeiXin do
  before(:all) do
    @weixin = WxExt::WeiXin.new 'flowerwrong@hotmail.com', '1*flower@wrong*1'
  end

  it 'should login to the mp' do
    res_hash = @weixin.login
    expect(res_hash[:status]).to eql(0)
  end

  it 'should init method should init all params' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      token = @weixin.token
      expect(token).to match(/\d+/)
		else
			expect(flag).to eql(true)
    end
  end

  it 'should search msg with keyword' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      require 'uri'
      ha = @weixin.get_msg_items(20, 7, 1, '','', '', '')
    end
  end

  it "should preview msg method should preview a msg to me" do
    res_hash = @weixin.login
    flag = @weixin.init
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    file_hash = @weixin.upload_file(file, "test.png")
    file_id = file_hash["content"]
    msg_params_with_name = {
      AppMsgId: '',
      ajax: 1,
      author0: '作者' + rand.to_s,
      can_reward0: 0,
      content0: '正文' + rand.to_s,
      copyright_type0: 0,
      count: 1,
      digest0: 'test摘要' + rand.to_s,
      f: 'json',
      fileid0: file_id,
      imgcode: '',
      lang: 'zh_CN',
      preusername: 'nan474947',
      random: rand,
      reward_wording0: '',
      shortvideofileid0: '',
      show_cover_pic0: 1,  # 0 => 封面图片不显示在正文中
      sourceurl0: 'http://thecampus.cc/' + rand.to_s,
      title0: 'test标题' + rand.to_s,
      token: @weixin.token,
      vid: ''
    }
    msg_hash = @weixin.preview_msg(msg_params_with_name)
    expect(msg_hash["ret"].to_s).to eql("0")
  end

=begin
  it 'should reply to yang' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      quick_reply_res_hash = @weixin.quick_reply('测试回复2', 201123100, 204060720)
      puts '==' * 20
      puts quick_reply_res_hash
      expect(quick_reply_res_hash['base_resp']['ret'].to_s).to eql('0')
    end
  end

  it 'should star msg' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      star_res_hash = @weixin.collect_msg('201123100')
      puts '==' * 20
      puts star_res_hash
      expect(star_res_hash['ret'].to_s).to eql('0')
    end
  end

  it 'should un star msg' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      star_res_hash = @weixin.un_collect_msg('201123100')
      puts '==' * 20
      puts star_res_hash
      expect(star_res_hash['ret'].to_s).to eql('0')
    end
  end
=end

  it 'should get fans count' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      fans_res_hash = @weixin.get_fans_count
      expect(fans_res_hash[:status]).to eql(0)
    end
  end

  it 'should get total_count, count, day, frommsgid, can_search_msg, offset, action=search, keyword, last_msg_id, filterivrmsg=0/1 和 msg_items' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      res_hash = @weixin.get_msg_items(20, 7, 1, '', '', '', '')
      expect(res_hash[:status]).to eql(0)
    else
      puts 'init failed'
    end
  end

  it "should get new msg num" do
    res_hash = @weixin.login
    flag = @weixin.init
    msg_res_hash = @weixin.get_msg_items if flag
    res_hash = @weixin.get_new_msg_num(msg_res_hash[:latest_msg_id=])
    expect(res_hash['ret'].to_s).to eql('0')
  end

  it 'should get day msg count' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      day_msg_count = @weixin.get_day_msg_count
      expect(day_msg_count.to_s).to match(/\d*/)
    end
  end

  it 'should get account message' do
    res_hash = @weixin.login
    flag = @weixin.init
    if flag
      account_message_res_hash = @weixin.get_account_message
      expect(account_message_res_hash.count).to eql(3)
    end
  end

  it "should get contact info" do
    res_hash = @weixin.login
    flag = @weixin.init
    res_hash = @weixin.get_contact_info('204060720')
    expect(res_hash['base_resp']['ret'].to_s).to eql('0')
  end

  it "should return a country list" do
    res_hash = @weixin.login
    flag = @weixin.init
    res_hash = @weixin.get_country_list
    expect(res_hash['num']).to eq(169)
  end

  it 'should upload_file method should return a right hash' do
    res_hash = @weixin.login
    flag = @weixin.init
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    file_hash = @weixin.upload_file(file, "test.png")
    expect(file_hash["base_resp"]["ret"].to_s).to eql("0")
  end

  it "should upload_single_msg method should upload a msg to sucaizhongxin" do
    res_hash = @weixin.login
    flag = @weixin.init
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    file_hash = @weixin.upload_file(file, "test.png")
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
        show_cover_pic0: 1, # 0 => 封面图片不显示在正文中
        sourceurl0: 'http://thecampus.cc/' + rand.to_s,
        title0: 'test标题' + rand.to_s,
        token: @weixin.token,
        vid: ''
    }
    msg_hash = @weixin.upload_single_msg(single_msg_params)
    expect(msg_hash["ret"].to_s).to eql("0")
  end

  it "should upload_multi_msg method should upload multi msg to sucaizhongxin" do
    res_hash = @weixin.login
    flag = @weixin.init
    file = File.new(File.join(WxExt.spec, "test.png"), 'rb')
    file_hash = @weixin.upload_file(file, "test.png")
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
    expect(msg_hash["ret"].to_s).to eql("0")
  end

=begin
  it "should broadcast msg to all user" do
    res_hash = @weixin.login
    flag = @weixin.init

    msg_hash = @weixin.get_app_msg_list
    puts "==" * 20
    app_msg_id = msg_hash["app_msg_info"]["item"][0]["app_id"]

    msg_params = {
        ajax: 1,
        appmsgid: app_msg_id,
        cardlimit: 1,
        city: '',
        country: '',
        province: '',
        f: 'json',
        groupid: '-1',
        imgcode: '',
        lang: 'zh_CN',
        operation_seq: @weixin.operation_seq,
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
=end

  it 'should get app msg list with json' do
    res_hash = @weixin.login
    flag = @weixin.init
    msg_hash = @weixin.get_app_msg_list
    expect(msg_hash["base_resp"]["ret"].to_s).to eql("0")
  end

  # 回复单个人的页面
  it 'should get singe send message' do
    @weixin.login
    @weixin.init
    single_hash = @weixin.single_send_page(608120400)
    expect(single_hash[:status]).to eql(0)
  end

  # 返回cookie
  it 'should get cookie' do
    cookie_hash = @weixin.get_cookie
    tmp = cookie_hash.is_a?(Hash)
    expect(tmp).to eq(true)
  end
end
