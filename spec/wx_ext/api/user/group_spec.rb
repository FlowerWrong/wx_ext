# encoding: UTF-8
require 'spec_helper'

describe WxExt::Api::User::Group do
=begin
  before(:all) do
    @app_id = 'app_id'
    @access_token_hash = WxExt::Api::Base.get_access_token('app_id', 'app_secret')
    @access_token = @access_token_hash['access_token']
  end

  it 'should create a group, then get all groups' do
    group_hash = WxExt::Api::User::Group.create_group(@access_token, '众联酒业')
    expect(group_hash['group']).not_to be_empty

    groups = WxExt::Api::User::Group.groups(@access_token)
    expect(groups).not_to be_empty
  end
=end
end
