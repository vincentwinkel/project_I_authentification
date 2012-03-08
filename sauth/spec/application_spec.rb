require_relative 'spec_helper'
require 'application'

describe Application do
	before(:each) do
		@a=Application.new;
		@url="http://url";
	end
	it "should be invalid (any name + any url)" do
		@a.valid?.should == false;
	end
	it "should store 'App1' name attribute" do
		@a.name="App1";
		@a.name.should == "App1";
	end
	it "should store 'http://url' in url attribute with argument 'http://url'" do
		@a.url="http://url";
		#@a.save;
		@a.url.should == @url;
	end
	it "should store 'http://url' in url attribute with argument 'url' without 'http://'" do
		@a.url="url";
		@a.url.should == @url;
	end
	it "should be invalid (any name)" do
		@a.url="url";
		@a.valid?.should == false;
	end
	it "should be invalid (any url)" do
		@a.name="App1";
		@a.valid?.should == false;
	end
	it "should be invalid (name already exists)" do
		@a.name="App1";
		@a.url="http://url1";
		@a.save;
		tmp_id=@a.id;
		@a=Application.new;
		@a.name="App1";
		@a.url="http://url2";
		@a.valid?.should == false;
		Application.delete(tmp_id);
	end
	it "should be invalid (url already exists)" do
		@a.name="App2";
		@a.url="http://url1";
		@a.save;
		tmp_id=@a.id;
		@a=Application.new;
		@a.name="App1";
		@a.url="http://url1";
		@a.valid?.should == false;
		Application.delete(tmp_id);
	end
	it "should be valid (name + url)" do
		@a.name="App1";
		@a.url="url";
		@a.should be_valid;
	end
end
