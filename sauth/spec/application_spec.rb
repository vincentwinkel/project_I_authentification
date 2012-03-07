require_relative 'spec_helper'
require 'application'

describe Application do
	before(:each) do
		@a=Application.new();
		@url="http://url";
	end
	it "should be invalid (any name + any url)" do
		@a.save;
		@a.valid?.should == false;
	end
	it "should store 'App1' name attribute" do
		@a.name="App1";
		@a.save;
		@a.name.should == "App1";
	end
	it "should store 'http://url' in url attribute with argument 'http://url'" do
		@a.url="http://url";
		@a.save;
		@a.url.should == @url;
	end
	it "should store 'http://url' in url attribute with argument 'url' without 'http://'" do
		@a.url="url";
		@a.save;
		@a.url.should == @url;
	end
	it "should be invalid (any name)" do
		@a.url="url";
		@a.save;
		@a.valid?.should == false;
	end
	it "should be invalid (any url)" do
		@a.name="App1";
		@a.save;
		@a.valid?.should == false;
	end
	it "should be valid (name + url)" do
		@a.name="App1";
		@a.url="url";
		@a.save;
		@a.should be_valid;
	end
end
