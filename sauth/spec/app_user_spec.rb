require_relative 'spec_helper'
require 'app_user'

describe AppUser do
	before(:each) do
		@au=AppUser.new;
		@au.id_app="10";
		@au.id_user="20";
	end
	it "should not be valid valid (link already exists)" do
		@au.save!;
		tmp_id=@au.id;
		@au.id_app="10";
		@au.id_user="20";
		@au.should be_valid;
		Application.delete(tmp_id);
	end
	it "should be valid" do
		@au.should be_valid;
	end
end
