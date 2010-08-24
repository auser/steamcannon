require 'spec_helper'

describe User do
  before(:each) do
    @valid_attributes = {
      :email => "test_user@mailinator.com",
      :password => "test_password",
      :password_confirmation => "test_password"
    }
  end

  it "should create a new instance given valid attributes" do
    User.create!(@valid_attributes)
  end

  it "should have a cloud_username attribute" do
    User.new.should respond_to(:cloud_username)
  end

  it "should have a cloud password attribute" do
    User.new.should respond_to(:cloud_password)
  end

  it "should have a cloud object" do
    User.new.should respond_to(:cloud)
  end

  it "should have many environments" do
    User.new.should respond_to(:environments)
  end

  it "should have many apps" do
    User.new.should respond_to(:apps)
  end

  it "should pass cloud credentials through to cloud object" do
    user = User.new(:cloud_username => 'user', :cloud_password => 'pass')
    Cloud::Deltacloud.should_receive(:new).with('user', 'pass')
    user.cloud
  end
end
