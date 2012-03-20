require_relative 'spec_helper';
require 'rack/test';

include Rack::Test::Methods;

def app
	Sinatra::Application;
end

#last_response.status.should be_redirect;
#follow_redirect!;
#last_request.path.should == "/path";

describe "Without session" do
	before(:each) do
		User.all.each { |u| User.delete(u.id); }
		Application.all.each { |u| Application.delete(u.id); }
	end
	#############################
	describe "Default page" do
	#############################
		it "should print the default page with a wrong URL" do
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
			params={"login" => "","password" => "toto","password_confirmation" => "toto"};
			post "/users", params;
			last_response.status.should == 200;
			settings.form_errors.should == {"login" => settings.ERROR_FORM_ANY_LOGIN};
		end
		it "should print again this page if an error occurred (any password)" do
			params={"login" => "titi","password" => "","password_confirmation" => "toto"};
			post "/users", params;
			last_response.status.should == 200;
			settings.form_errors.should == {"password" => settings.ERROR_FORM_ANY_PASS};
		end
		it "should print again this page if an error occurred (any password_confirmation)" do
			params={"login" => "titi","password" => "toto","password_confirmation" => ""};
			post "/users", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"password" => "",
				"password_confirmation" => settings.ERROR_FORM_BAD_PASS_CONFIRM
			};
		end
		it "should print again this page if an error occurred (any params)" do
			params={"login" => "","password" => "","password_confirmation" => ""};
			post "/users", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"login" => settings.ERROR_FORM_ANY_LOGIN,
				"password" => settings.ERROR_FORM_ANY_PASS
			};
		end
		it "should print again this page if an error occurred (all params but" \
			"password != password_confirm)" do
			params={"login" => "titi","password" => "toto","password_confirmation" => "tata"};
			post "/users", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"password" => "",
				"password_confirmation" => settings.ERROR_FORM_BAD_PASS_CONFIRM
			};
		end
		it "should print again this page if an error occurred (account already exists)" do
			u=User.new({:login => "login_test",:password => "mdp"});
			u.save!;
			params={"login" => "login_test","password" => "mdp","password_confirmation" => "mdp"};
			post "/users", params;
			last_response.status.should == 200;
			settings.form_errors.should == {"login" => settings.ERROR_FORM_BAD_LOGIN};
		end
		it "should redirect to the protected area (any error)" do
			params={"login" => "login_test","password" => "mdp","password_confirmation" => "mdp"};
			post "/users", params;
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should match %r{/users/\d+};
			last_request.session["s_user"].should == "login_test";
			last_request.session["s_id"].should > 0;
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
				params={"login" => "","password" => "toto"};
				post "/sessions", params;
				last_response.status.should == 200;
				settings.form_errors.should == {"login" => settings.ERROR_FORM_ANY_LOGIN};
			end
			it "should print again this page if an error occurred (any password)" do
				params={"login" => "titi","password" => ""};
				post "/sessions", params;
				last_response.status.should == 200;
				settings.form_errors.should == {"password" => settings.ERROR_FORM_ANY_PASS};
			end
			it "should print again this page if an error occurred (any params)" do
				params={"login" => "","password" => ""};
				post "/sessions", params;
				last_response.status.should == 200;
				settings.form_errors.should == {
					"login" => settings.ERROR_FORM_ANY_LOGIN,
					"password" => settings.ERROR_FORM_ANY_PASS
				};
			end
			it "should print again this page if an error occurred (account no exists)" do
				params={"login" => "User_no_exists","password" => "mdp"};
				post "/sessions", params;
				last_response.status.should == 200;
				settings.form_errors.should == {"login" => settings.ERROR_FORM_NO_LOGIN};
			end
			it "should redirect to the protected area (any error)" do
				u=User.new({:login => "login_test",:password => "mdp"});
				u.save!;
				params={"login" => "login_test","password" => "mdp"};
				post "/sessions", params;
				last_response.status.should == 302;
				follow_redirect!;
				last_request.path.should == ("/users/" + u.id.to_s);
				last_request.session["s_user"].should == "login_test";
				last_request.session["s_id"].should > 0;
			end
		end
		describe "from an existing external app" do
			before(:each) do
				@u=User.new({:login => "login_test",:password => "mdp"});
				@u.save!;
				@tmp_id=@u.id;
				@a=Application.new({:name => "app_test",:url => "http://url",:admin => "1"});
				@a.save!;
				@tmp_aid=@a.id;
			end
			it "should print the page" do
				get ("/" + @tmp_aid.to_s + "/sessions/new?ref=/test");
				last_response.status.should == 200;
			end
			it "should print the error apps page" do
				get ("/" + @tmp_aid.to_s + "/sessions/new");
				last_response.status.should == 200;
				last_response.body.should match %r{<title>Application inconnue</title>};
			end
			it "should print again the page (bad params)" do
				params={
					"login" => "",
					"password" => "",
					"origin" => "http://url/test",
					"aid" => @tmp_aid
				};
				post "/apps/sessions", params;
				last_response.status.should == 200;
				settings.origin.should == "http://url/test";
			end
			it "should redirect to the origin link (good params)" do
				AppUser.should_receive(:create); #Ensure a create() method call
				params={
					"login" => "login_test",
					"password" => "mdp",
					"origin" => "http://url/test",
					"aid" => @tmp_aid
				};
				post "/apps/sessions", params;
				last_response.status.should == 302;
				follow_redirect!;
				last_request.url.should == "http://url/test?key=sauth4567";
			end
		end
		describe "from an unknown external app" do
			it "should print the error apps page" do
				get "0/sessions/new?ref=/test";
				last_response.status.should == 200;
				last_response.body.should match %r{<title>Application inconnue</title>};
			end
		end
	end
	#############################
	describe "Deconnection page" do
	#############################
		it "should print the connection page" do
			get "/sessions/destroy";
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == "/sessions/new";
			last_request.session["s_user"].should be_nil;
			last_request.session["s_id"].should be_nil;
		end
	end
	#############################
	describe "Protected area" do
	#############################
		it "should redirect to the connection page" do
			get "/users/1";
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == "/sessions/new";
			last_request.session["s_user"].should be_nil;
			last_request.session["s_id"].should be_nil;
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
			last_request.session["s_user"].should be_nil;
			last_request.session["s_id"].should be_nil;
		end
	end
end


describe "With session" do
	before(:each) do
		User.all.each { |u| User.delete(u.id); }
		Application.all.each { |a| Application.delete(a.id); }
		AppUser.all.each { |au| AppUser.delete(au.id); }
		u=User.new({:login => "login_test",:password => "mdp"});
		u.save!;
		@tmp_id=u.id;
		params={"login" => "login_test","password" => "mdp"};
		post "/sessions", params;
	end
	#############################
	describe "Default page" do
	#############################
		it "should print the default page with a wrong URL" do
			get "/wrong_url";
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == "/sessions/new";
			last_request.session["s_user"].should == "login_test";
			last_request.session["s_id"].should == @tmp_id;
		end
	end
	#############################
	describe "Inscription page" do
	#############################
		it "should redirect to the protected area" do
			get "/users/new";
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == ("/users/" + @tmp_id.to_s);
			last_request.session["s_user"].should == "login_test";
			last_request.session["s_id"].should == @tmp_id;
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
				last_request.path.should == ("/users/" + @tmp_id.to_s);
				last_request.session["s_user"].should == "login_test";
				last_request.session["s_id"].should == @tmp_id;
			end
		end
		describe "from an existing external app" do
			it "should directly redirect to the origin link with good params" do
				#AppUser.should_receive(:find_by_id_user);
				a=Application.new({:name => "app_test",:url => "http://url",:admin => "1"});
				a.save!;
				get ("/" + a.id.to_s + "/sessions/new?ref=/test");
				last_response.status.should == 302;
				follow_redirect!;
				last_request.url.should == "http://url/test?key=sauth4567";
			end
		end
	end
	#############################
	describe "Deconnection page" do
	#############################
		it "should destroy the current session" do
			get "/sessions/destroy";
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == "/sessions/new";
			last_request.session["s_user"].should be_nil;
			last_request.session["s_id"].should be_nil;
		end
	end
	#############################
	describe "Protected area" do
	#############################
		it "should print the page" do
			get ("/users/" + @tmp_id.to_s);
			last_response.status.should == 200;
			last_request.session["s_user"].should == "login_test";
			last_request.session["s_id"].should == @tmp_id;
		end
	end
	#############################
	describe "Protected area of another user" do
	#############################
		it "should print the page" do
			get ("/users/1");
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == "/sessions/new";
			follow_redirect!;
			last_request.path.should == ("/users/" + @tmp_id.to_s);
			last_request.session["s_user"].should == "login_test";
			last_request.session["s_id"].should == @tmp_id;
		end
	end
	#############################
	describe "Add application page" do
	#############################
		it "should print the page" do
			get "/apps/new";
			last_response.status.should == 200;
			last_request.session["s_user"].should == "login_test";
			last_request.session["s_id"].should == @tmp_id;
		end
		it "should print again this page if an error occurred (any name)" do
			params={"name" => "","url" => "http://url"};
			post "/apps", params;
			last_response.status.should == 200;
			settings.form_errors.should == {"name" => settings.ERROR_FORM_ANY_NAME};
		end
		it "should print again this page if an error occurred (any url)" do
			params={"name" => "app_test","url" => ""};
			post "/apps", params;
			last_response.status.should == 200;
			settings.form_errors.should == {"url" => settings.ERROR_FORM_ANY_URL};
		end
		it "should print again this page if an error occurred (any params)" do
			params={"name" => "","url" => ""};
			post "/apps", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"name" => settings.ERROR_FORM_ANY_NAME,
				"url" => settings.ERROR_FORM_ANY_URL
			};
		end
		it "should redirect to protected area after a new app was created" do
			params={"name" => "app_test","url" => "http://url"};
			post "/apps", params;
			last_response.status.should == 302;
			follow_redirect!;
			last_request.path.should == ("/users/" + @tmp_id.to_s);
			last_response.body.should match \
				%r{<a class="app_admin" href="http://url" target="_blank">app_test};
		end
		#############################
		describe "Actions from protected area" do
		#############################
			before(:each) do
				a1=Application.new({:name => "app_test1",:url => "http://url1",:admin => @tmp_id});
				a1.save!;
				@tmp_aid1=a1.id;
				a2=Application.new({:name => "app_test2",:url => "http://url2",:admin => "1"});
				a2.save!;
				tmp_aid2=a2.id;
				au1=AppUser.new({:id_app => @tmp_aid1,:id_user => @tmp_id});
				au1.save!;
				au2=AppUser.new({:id_app => tmp_aid2,:id_user => @tmp_id});
				au2.save!;
			end
			it "should list all apps the user uses and he supervises" do
				get ("/users/" + @tmp_id.to_s);
				last_response.body.should match \
					%r{<a class="app_used" href="http://url1" target="_blank">app_test1};
				last_response.body.should match \
					%r{<a class="app_used" href="http://url2" target="_blank">app_test2};
				last_response.body.should match \
					%r{<a class="app_admin" href="http://url1" target="_blank">app_test1};
				last_response.body.should_not match \
					%r{<a class="app_admin" href="http://url2" target="_blank">app_test2};
			end
			it "should destroy an app" do
				get ("/apps/destroy/" + @tmp_aid1.to_s);
				last_response.status.should == 302;
				follow_redirect!;
				last_request.path.should == ("/users/" + @tmp_id.to_s);
				last_response.body.should_not match \
					%r{<a class="app_admin" href="http://url1" target="_blank">app_test1};
			end
		end
	end
end
