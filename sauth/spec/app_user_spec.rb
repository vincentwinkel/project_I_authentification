require_relative 'spec_helper';
require 'app_user';

describe AppUser do
  before(:each) do
    AppUser.destroy_all;
    @au=AppUser.new({:application_id => 10,:user_id => 20});
  end
  it "should be valid" do
    @au.save!;
    @au.should be_valid;
  end
  it "should not duplicate user for a same app" do
    @au.save!;
    AppUser.add_user_for_app(10,20);
    us=AppUser.find_all_by_application_id(10).size.should == 1;
  end
  it "should add new user for a same app" do
    @au.save!;
    AppUser.add_user_for_app(10,21);
    us=AppUser.find_all_by_application_id(10).size.should == 2;
  end
  describe "DataBase actions" do
    before(:each) do
      @au.save!;
      @au2=AppUser.create!({:application_id => 10,:user_id => 21});
      @au3=AppUser.create!({:application_id => 11,:user_id => 21});
    end
    it "should delete all apps used by a user" do
      AppUser.delete_for_user(21);
      AppUser.find_by_user_id(21).should be_nil;
    end
    it "should return all apps used by a user" do
      AppUser.get_apps_for_user(21).should == {10 => [nil,nil],11 => [nil,nil]};
    end
    it "should delete all users using an app" do
      AppUser.delete_for_app(10);
      AppUser.find_by_application_id(10).should be_nil;
    end
    it "should return all users using an app" do
      AppUser.get_users_for_app(10).should == {20 => nil,21 => nil};
    end
  end
end
