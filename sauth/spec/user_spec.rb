require_relative 'spec_helper'
require 'user'

describe User do
  before(:each) do
    User.destroy_all;
    @u=User.new;
    @crypt="00d70c561892a94980befd12a400e26aeb4b8599";
    User.stub(:encrypt).and_return(@crypt);
  end
  it "should be invalid (any login + any password)" do
    @u.valid?.should be_false;
  end
  it "should store 'login_test' in login attribute" do
    @u.login="login_test";
    @u.login.should == "login_test";
  end
  it "should store sha1('mdp') in password attribute" do
    @u.password="mdp";
    @u.password.should == @crypt;
  end
  it "should be invalid (any login)" do
    @u.password="mdp";
    @u.valid?.should be_false;
  end
  it "should be invalid (any password)" do
    @u.login="login_test";
    @u.valid?.should be_false;
  end
  it "should be invalid (login already exists)" do
    @u.login="login_test";
    @u.password="mdp";
    @u.save!;
    @u=User.new({:login => "login_test",:password => "mdp"});
    @u.valid?.should be_false;
  end
  it "should be valid (login + password)" do
    @u.login="login_test";
    @u.password="mdp";
    @u.should be_valid;
  end
end
