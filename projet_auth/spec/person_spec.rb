require_relative 'spec_helper'
require 'person'

describe Person do
	before(:each) do
		@p=Person.new();
	end
	it "should be invalid (any login + any password)" do
		@p.valid?.should == false;
	end
	it "should be invalid (any login)" do
		@p.password="mdp";
		@p.valid?.should == false;
	end
	it "should be invalid (any password)" do
		@p.login="Vincent";
		@p.valid?.should == false;
	end
	it "should be valid (login + password)" do
		@p.login="Vincent";
		@p.password="mdp";
		@p.should be_valid;
	end
	it "should store 'Vincent' login attribute" do
		@p.login="Vincent";
		@p.login.should == "Vincent";
	end
	it "should store 'mdp' password attribute" do
		@p.password="mdp";
		@p.password.should == "mdp";
	end
end
