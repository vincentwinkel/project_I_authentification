require_relative 'spec_helper'
require 'appUser'

describe User do
	before(:each) do
		@au=appUser.new();
	end
	it "should be invalid (any id_app + any id_user)" do
		@au.valid?.should == false;
	end
	it "should store '1' in id_app attribute" do
		@au.id_app="1";
		@au.id_app.should == "2";
	end
	it "should store the integer '2' in id_user attribute" do
		@au.id_user="2";
		@au.id_user.should == "2";
	end
	it "should store the string 'data' in url attribute" do
		@a.id_user=2;
		@a.id_user.should == "2";
	end
	it "should be invalid (any id_app)" do
		@au.id_user="2";
		@au.valid?.should == false;
	end
	it "should be invalid (any id_user)" do
		@au.id_app="1";
		@au.valid?.should == false;
	end
	it "should be valid (id_app + id_user)" do
		@au.id_app="1";
		@au.id_user="2";
		@au.should be_valid;
	end
end
