require_relative 'spec_helper'
require 'user'

describe User do
	before(:each) do
		@u=User.new();
		@crypt="00d70c561892a94980befd12a400e26aeb4b8599";
		@u.encode.stub(:hexdigest).and_return(@crypt);
	end
	it "should be invalid (any login + any password)" do
		@u.save;
		@u.valid?.should == false;
	end
	it "should store 'Vincent' in login attribute" do
		@u.login="Vincent";
		@u.save;
		@u.login.should == "Vincent";
	end
	it "should store sha1('mdp') in password attribute" do
		@u.password="mdp";
		@u.save;
		@u.password.should == @crypt;
	end
	it "should be invalid (any login)" do
		@u.password="mdp";
		@u.save;
		@u.valid?.should == false;
	end
	it "should be invalid (any password)" do
		@u.login="Vincent";
		@u.save;
		@u.valid?.should == false;
	end
	it "should be valid (login + password)" do
		@u.login="Vincent";
		@u.password="mdp";
		@u.save;
		@u.should be_valid;
	end
end
