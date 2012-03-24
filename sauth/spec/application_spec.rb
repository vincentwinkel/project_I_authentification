require_relative 'spec_helper';
require 'application';

describe Application do
  before(:each) do
    Application.destroy_all;
    @a=Application.new;
    @url="http://url";
  end
  it "should be invalid (any name + any url + any admin)" do
    @a.valid?.should be_false;
  end
  it "should store 'app_test' in name attribute" do
    @a.name="app_test";
    @a.name.should == "app_test";
  end
  it "should store 'http://url' in url attribute with argument 'http://url'" do
    @a.url="http://url";
    @a.url.should == @url;
  end
  it "should store 'http://url' in url attribute with argument 'url' without 'http://'" do
    @a.url="url";
    @a.url.should == @url;
  end
  it "should store '123' in admin attribute" do
    @a.name=123;
    @a.name.should == 123;
  end
  it "should be invalid (any name)" do
    @a.url="url";
    @a.admin=123;
    @a.valid?.should be_false;
  end
  it "should be invalid (any url)" do
    @a.name="app_test";
    @a.admin=123;
    @a.valid?.should be_false;
  end
  it "should be invalid (any admin)" do
    @a.name="app_test";
    @a.url="http://url";
    @a.valid?.should be_false;
  end
  it "should be invalid (name already exists)" do
    @a.name="app_test";
    @a.url="http://url1";
    @a.admin=123;
    @a.save!;
    @a=Application.new({:name => "app_test",:url => "http://url2",:admin => 123});
    @a.valid?.should be_false;
  end
  it "should be invalid (url already exists)" do
    @a.name="App2";
    @a.url="http://url1";
    @a.admin=123;
    @a.save!;
    @a=Application.new({:name => "app_test",:url => "http://url1",:admin => 123});
    @a.valid?.should be_false;
  end
  it "should be valid (name + url)" do
    @a.name="app_test";
    @a.url="url";
    @a.admin=123;
    @a.should be_valid;
  end
  it "should be return all apps for an admin" do
    @a.name="app_test1";
    @a.url="url1";
    @a.admin=123;
    @a.save!;
    tmp_aid=@a.id;
    @a=Application.create!({:name => "app_test2",:url => "url2",:admin => 123});
    Application.get_apps_for_admin(123).should == {
      tmp_aid => ["app_test1","http://url1"],
      @a.id => ["app_test2", "http://url2"]
    };
  end
end
