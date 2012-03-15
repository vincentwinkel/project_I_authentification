require_relative 'spec_helper'
require 'user'

describe User do
	before(:each) do
		@u=User.new;
		@crypt="00d70c561892a94980befd12a400e26aeb4b8599";
		@u.encode.stub(:hexdigest).and_return(@crypt);
	end
	it "should be invalid (any login + any password)" do
		@u.valid?.should == false;
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
		@u.valid?.should == false;
	end
	it "should be invalid (any password)" do
		@u.login="login_test";
		@u.valid?.should == false;
	end
	it "should be invalid (login already exists)" do
		@u.login="login_test";
		@u.password="mdp";
		@u.save!;
		tmp_id=@u.id;
		@u=User.new;
		@u.login="login_test";
		@u.password="mdp";
		@u.valid?.should == false;
		User.delete(tmp_id);
	end
	it "should be valid (login + password)" do
		@u.login="login_test";
		@u.password="mdp";
		@u.should be_valid;
	end
end
