require_relative 'spec_helper'
require 'app_user'

describe AppUser do
	before(:each) do
		AppUser.all.each { |au| AppUser.delete(au.id); }
		@au=AppUser.new({:id_app => "10",:id_user => "20"});
	end
	it "should not be valid valid (link already exists)" do
		@au.save!;
		@au.id_app="10";
		@au.id_user="20";
		@au.should be_valid;
	end
	it "should be valid" do
		@au.should be_valid;
	end
	describe "Data Base actions" do
		before(:each) do
			@au.save!;
			@au2=AppUser.new({:id_app => "10",:id_user => "21"});
			@au2.save!;
			@au3=AppUser.new({:id_app => "11",:id_user => "21"});
			@au3.save!;
		end
		it "should delete all apps used by a user" do
			AppUser.delete_for_user("21");
			AppUser.find_by_id_user("21").should be_nil;
		end
		it "should return all apps used by a user" do
			AppUser.get_apps_for_user("21").should == {"10" => [nil,nil],"11" => [nil,nil]};
		end
		it "should delete all users using an app" do
			AppUser.delete_for_app("10");
			AppUser.find_by_id_app("10").should be_nil;
		end
		it "should return all users using an app" do
			AppUser.get_users_for_app("10").should == {"20" => nil,"21" => nil};
		end
	end
end
