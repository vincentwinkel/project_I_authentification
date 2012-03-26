require_relative 'spec_helper';
require 'rack/test';
require_relative '../sauth';
include Rack::Test::Methods;

def app
  Sinatra::Application;
end

describe "Without session" do
  before(:each) do
    User.destroy_all;
    Application.destroy_all;
    @crypt="00d70c561892a94980befd12a400e26aeb4b8599";
    @user=User.new({:login => "login_test",:password => "mdp"});
    @user.stub(:id).and_return(1);
    User.stub(:new).and_return(@user);
    User.stub(:find_by_login).and_return(@user);
  end
  #############################
  describe "Default page" do
  #############################
    it "should print the connection page with a wrong URL" do
      get "/wrong_url";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
    end
  end
  #############################
  describe "Inscription page" do
  #############################
    it "should print the inscription page" do
      get "/users/new";
      last_response.status.should == 200;
    end
    it "should print again this page if an error occurred (any login)" do
      post "/users", {:user => {:login => "",:password => "mdp"},:password_confirmation => "mdp"};
      last_response.status.should == 200;
      settings.form_errors.should == {:login => settings.ERROR_FORM_ANY_LOGIN};
    end
    it "should print again this page if an error occurred (any password)" do
      post "/users", {
        :user => {:login => "login_test",:password => ""},
        :password_confirmation => "mdp"
      };
      last_response.status.should == 200;
      settings.form_errors.should == {:password => settings.ERROR_FORM_ANY_PASS};
    end
    it "should print again this page if an error occurred (any password_confirmation)" do
      post "/users", {
        :user => {:login => "login_test",:password => "mdp"},
        :password_confirmation => ""
      };
      last_response.status.should == 200;
      settings.form_errors.should == {
        :password => "",
        :password_confirmation => settings.ERROR_FORM_BAD_PASS_CONFIRM
      };
    end
    it "should print again this page if an error occurred (any params)" do
      post "/users", {:user => {:login => "",:password => ""},:password_confirmation => ""};
      last_response.status.should == 200;
      settings.form_errors.should == {
        :login => settings.ERROR_FORM_ANY_LOGIN,
        :password => settings.ERROR_FORM_ANY_PASS
      };
    end
    it "should print again this page if an error occurred (all params but" \
      "password != password_confirm)" do
      post "/users", {
        :user => {:login => "login_test",:password => "mdp1"},
        :password_confirmation => "mdp2"
      };
      last_response.status.should == 200;
      settings.form_errors.should == {
        :password => "",
        :password_confirmation => settings.ERROR_FORM_BAD_PASS_CONFIRM
      };
    end
    it "should print again this page if an error occurred (account already exists)" do
      @user.stub(:valid?).and_return(false);
      post "/users", {
        :user => {:login => "login_test",:password => "mdp"},
        :password_confirmation => "mdp"
      };
      last_response.status.should == 200;
      settings.form_errors.should == {:login => settings.ERROR_FORM_BAD_LOGIN};
    end
    it "should redirect to the protected area (any error)" do
      @user.stub(:valid?).and_return(true);
      @user.stub(:save).and_return(true);
      @user.should_receive(:save);
      post "/users", {
        :user => {:login => "login_test",:password => "mdp"},
        :password_confirmation => "mdp"
      };
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should match %r{/users/\d+};
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].to_i.should > 0;
    end
  end
  #############################
  describe "Connection page" do
  #############################
    describe "from the sauth" do
      it "should print the connection page" do
        get "/sessions/new";
        last_response.status.should == 200;
      end
      it "should print again this page if an error occurred (any login)" do
        post "/sessions", {:user => {:login => "",:password => "toto"}};
        last_response.status.should == 200;
        settings.form_errors.should == {:login => settings.ERROR_FORM_ANY_LOGIN};
      end
      it "should print again this page if an error occurred (any password)" do
        post "/sessions", {:user => {:login => "titi",:password => ""}};
        last_response.status.should == 200;
        settings.form_errors.should == {:password => settings.ERROR_FORM_ANY_PASS};
      end
      it "should print again this page if an error occurred (any params)" do
        post "/sessions", {:user => {:login => "",:password => ""}};
        last_response.status.should == 200;
        settings.form_errors.should == {
          :login => settings.ERROR_FORM_ANY_LOGIN,
          :password => settings.ERROR_FORM_ANY_PASS
        };
      end
      it "should print again this page if an error occurred (account no exists)" do
        User.stub(:find_by_login).and_return(nil);
        post "/sessions", {:user => {:login => "User_no_exists",:password => "mdp"}};
        last_response.status.should == 200;
        settings.form_errors.should == {:login => settings.ERROR_FORM_NO_LOGIN};
      end
      it "should redirect to the protected area (any error)" do
        User.stub(:find_by_login).and_return(@user);
        post "/sessions", {:user => {:login => "login_test",:password => "mdp"}};
        last_response.status.should == 302;
        follow_redirect!;
        last_request.path.should == "/users/#{@user.id}";
        last_request.session[:s_user].should == "login_test";
        last_request.session[:s_id].should > 0;
      end
    end
    describe "from an existing external app" do
      before(:each) do
        @user.stub(:valid?).and_return(false);
        @app=Application.new({:name => "app_test",:url => "http://url"});
        @app.stub(:id).and_return(1);
        Application.stub(:new).and_return(@app);
        @app.stub(:valid?).and_return(false);
      end
      it "should print the page" do
        get "/#{@app.id}/sessions/new?ref=/test";
        last_response.status.should == 200;
      end
      it "should print again the page (bad params)" do
        post "/apps/sessions", {
          :user => {:login => "",:password => ""},
          :origin => "http://url/test",
          :aid => @app.id
        };
        last_response.status.should == 200;
        settings.origin.should == "http://url/test";
      end
      it "should redirect to the original link (good params)" do
        AppUser.should_receive(:add_user_for_app).with(@app.id,@user.id);
        post "/apps/sessions", {
          :user => {:login => "login_test",:password => "mdp"},
          :origin => "http://url/test",
          :aid => @app.id
        };
        last_response.status.should == 302;
        follow_redirect!;
        last_request.url.should == "http://url/test?login=login_test&key=sauth4567";
      end
    end
    describe "from an unknown external app" do
      it "should print the error apps page" do
        get "0/sessions/new?ref=/test";
        last_response.status.should == 200;
        last_response.body.should match %r{Application inconnue</title>};
      end
    end
  end
  #############################
  describe "Deconnection page" do
  #############################
    it "should redirect to the connection page" do
      delete "/sessions/0";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      last_request.session[:s_user].should be_nil;
      last_request.session[:s_id].should be_nil;
    end
  end
  #############################
  describe "Protected area" do
  #############################
    it "should redirect to the connection page" do
      get "/users/0";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      last_request.session[:s_user].should be_nil;
      last_request.session[:s_id].should be_nil;
    end
  end
  #############################
  describe "Add application page" do
  #############################
    it "should redirect to the connection page" do
      get "/apps/new";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      last_request.session[:s_user].should be_nil;
      last_request.session[:s_id].should == nil;
    end
  end
end

describe "With session" do
  before(:each) do
    User.destroy_all;
    Application.destroy_all;
    AppUser.destroy_all;
    @u=User.create!({:login => "login_test",:password => "mdp"});
    @tmp_id=@u.id;
    @crypt="00d70c561892a94980befd12a400e26aeb4b8599";
    User.should_receive(:encrypt).with("mdp").at_least(1).and_return(@crypt);
    #Already tested
    post "/sessions", {:user => {:login => "login_test",:password => "mdp"}};
  end
  #############################
  describe "Default page" do
  #############################
    it "should print the connection page with a wrong URL" do
      get "/wrong_url";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].should == @tmp_id;
    end
  end
  #############################
  describe "Inscription page" do
  #############################
    it "should redirect to the protected area" do
      get "/users/new";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/users/#{@tmp_id}";
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].should == @tmp_id;
    end
  end
  #############################
  describe "Connection page" do
  #############################
    describe "from the sauth" do
      it "should redirect to the protected area" do
        get "/sessions/new";
        last_response.status.should == 302;
        follow_redirect!;
        last_request.path.should == "/users/#{@tmp_id}";
        last_request.session[:s_user].should == "login_test";
        last_request.session[:s_id].should == @tmp_id;
      end
    end
    describe "from an existing external app" do
      it "should directly redirect to the original link with good params" do
        a=Application.create!({:name => "app_test",:url => "http://url",:admin => 1});
        AppUser.should_receive(:add_user_for_app).with(a.id,@tmp_id);
        get "/#{a.id}/sessions/new?ref=/test";
        last_response.status.should == 302;
        follow_redirect!;
        last_request.url.should == "http://url/test?login=login_test&key=sauth4567";
      end
    end
  end
  #############################
  describe "Deconnection page" do
  #############################
    it "should redirect to the connection page after the current session was destroyed" do
      delete "/sessions/#{@tmp_id}";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      last_request.session[:s_user].should be_nil;
      last_request.session[:s_id].should be_nil;
    end
  end
  #############################
  describe "Deconnection page of another user" do
  #############################
    it "should redirect to the connection page" do
      delete "/sessions/1";
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].should == @tmp_id;
    end
  end
  #############################
  describe "Protected area" do
  #############################
    it "should print the page" do
      get "/users/#{@tmp_id}";
      last_response.status.should == 200;
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].should == @tmp_id;
    end
  end
  #############################
  describe "Protected area of another user" do
  #############################
    it "should redirect to the connection page" do
      get ("/users/1");
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/sessions/new";
      follow_redirect!;
      last_request.path.should == "/users/#{@tmp_id}";
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].should == @tmp_id;
    end
  end
  #############################
  describe "Add application page" do
  #############################
    it "should print the page" do
      get "/apps/new";
      last_response.status.should == 200;
      last_request.session[:s_user].should == "login_test";
      last_request.session[:s_id].should == @tmp_id;
    end
    it "should print again this page if an error occurred (any name)" do
      post "/apps", {:application => {:name => "",:url => "http://url"}};
      last_response.status.should == 200;
      settings.form_errors.should == {:name => settings.ERROR_FORM_ANY_NAME};
    end
    it "should print again this page if an error occurred (any url)" do
      post "/apps", {:application => {:name => "app_test",:url => ""}};
      last_response.status.should == 200;
      settings.form_errors.should == {:url => settings.ERROR_FORM_ANY_URL};
    end
    it "should print again this page if an error occurred (any params)" do
      post "/apps", {:application => {:name => "",:url => ""}};
      last_response.status.should == 200;
      settings.form_errors.should == {
        :name => settings.ERROR_FORM_ANY_NAME,
        :url => settings.ERROR_FORM_ANY_URL
      };
    end
    it "should print again this page if an error occurred (app already exists)" do
      app=Application.new({:name => "app_test",:url => "http://url", :admin => 1});
      Application.stub(:new).and_return(app);
      app.stub(:valid?).and_return(false);
      post "/apps", {:application => {:name => "app_test",:url => "http://url"}};
      last_response.status.should == 200;
      settings.form_errors.should == {
        :name => settings.ERROR_FORM_BAD_NAME,
        :url => settings.ERROR_FORM_BAD_URL
      };
    end
    it "should redirect to protected area after a new app was created" do
      app=Application.new({:name => "app_test",:url => "http://url", :admin => 1});
      Application.stub(:new).and_return(app);
      app.stub(:valid?).and_return(true);
      app.stub(:save).and_return(true);
      Application.stub(:get_apps_for_admin).and_return({[1] => ["app_test","http://url"]});
      post "/apps", {:application => {:name => "app_test",:url => "http://url"}};
      last_response.status.should == 302;
      follow_redirect!;
      last_request.path.should == "/users/#{@tmp_id}";
      last_response.body.should match \
        %r{<a class="app_admin" href="http://url" target="_blank">app_test};
    end
    #############################
    describe "Actions from protected area" do
    #############################
      before(:each) do
        a1=Application.create!({:name => "app_test1",:url => "http://url1",:admin => @tmp_id});
        @tmp_aid1=a1.id;
        a2=Application.create!({:name => "app_test2",:url => "http://url2",:admin => 1});
        @tmp_aid2=a2.id;
        au1=AppUser.create!({:application_id => @tmp_aid1,:user_id => @tmp_id});
        au2=AppUser.create!({:application_id => @tmp_aid2,:user_id => @tmp_id});
      end
      it "should list all apps the user uses and he supervises" do
        AppUser.should_receive(:get_apps_for_user).with(@tmp_id).and_return({
          [@tmp_aid1] => ["app_test1","http://url1"],
          [@tmp_aid2] => ["app_test2","http://url2"]
        });
        Application.should_receive(:get_apps_for_admin).with(@tmp_id).and_return({
          [@tmp_aid2] => ["app_test1","http://url1"]
        });
        get "/users/#{@tmp_id}";
        last_response.body.should match \
          %r{<a class="app_used" href="http://url1" target="_blank">app_test1};
        last_response.body.should match \
          %r{<a class="app_used" href="http://url2" target="_blank">app_test2};
        last_response.body.should match \
          %r{<a class="app_admin" href="http://url1" target="_blank">app_test1};
        last_response.body.should_not match \
          %r{<a class="app_admin" href="http://url2" target="_blank">app_test2};
      end
      it "should destroy an app and dependencies" do
        AppUser.should_receive(:delete_for_app).with(@tmp_aid1);
        delete "/apps/#{@tmp_aid1}";
        last_response.status.should == 302;
        follow_redirect!;
        last_request.path.should == "/users/#{@tmp_id}";
        last_response.body.should_not match \
          %r{<a class="app_used" href="http://url1" target="_blank">app_test1};
        last_response.body.should_not match \
          %r{<a class="app_admin" href="http://url1" target="_blank">app_test1};
      end
    end
  end
end
