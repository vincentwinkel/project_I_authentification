require_relative 'spec_helper'
require 'app_user'

describe AppUser do
	before(:each) do
		@a=Application.new();
		@a.name="App1";
		@a.url="http://url";
		@u=User.new();
		@u.login="Vincent";
		@u.password="mdp";
		@au=AppUser.new();
	end
	it "should be valid" do
		@au.id_app="10";
		@au.id_user="20";
		@au.save;
		@au.should be_valid;
	end
end
