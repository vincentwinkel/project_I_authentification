require_relative 'spec_helper';
require 'rack/test';

include Rack::Test::Methods;

def app
	Sinatra::Application;
end

describe "Without session" do
	before(:each) do
		#session={};
	end
	describe "Default page" do
		it "should print the default page with a wrong URL" do
			get "/wrong_url";
			last_response.status.should == 302;
			last_response.header["Location"].should == "http://example.org/sessions/new";
		end
	end
	describe "Inscription page" do
		it "should print the inscription page" do
			get "/register";
			last_response.status.should == 200;
		end
		it "should print again this page if an error occurred (any login)" do
			params={"login" => "","password" => "toto","password_confirmation" => "toto"};
			post "/register", params;
			last_response.status.should == 200;
			settings.form_errors.should == { "login" => settings.ERROR_FORM_ANY_LOGIN };
		end
		it "should print again this page if an error occurred (any password)" do
			params={"login" => "titi","password" => "","password_confirmation" => "toto"};
			post "/register", params;
			last_response.status.should == 200;
			settings.form_errors.should == { "password" => settings.ERROR_FORM_ANY_PASS };
		end
		it "should print again this page if an error occurred (any password_confirmation)" do
			params={"login" => "titi","password" => "toto","password_confirmation" => ""};
			post "/register", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"password" => "",
				"password_confirmation" => settings.ERROR_FORM_BAD_PASS_CONFIRM
			};
		end
		it "should print again this page if an error occurred (any params)" do
			params={"login" => "","password" => "","password_confirmation" => ""};
			post "/register", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"login" => settings.ERROR_FORM_ANY_LOGIN,
				"password" => settings.ERROR_FORM_ANY_PASS
			};
		end
		it "should print again this page if an error occurred (all params but" \
			"password != password_confirm)" do
			params={"login" => "titi","password" => "toto","password_confirmation" => "tata"};
			post "/register", params;
			last_response.status.should == 200;
			settings.form_errors.should == {
				"password" => "",
				"password_confirmation" => settings.ERROR_FORM_BAD_PASS_CONFIRM
			};
		end
		it "should redirect to the protected area (any error)" do
			params={"login" => "titi","password" => "toto","password_confirmation" => "toto"};
			post "/register", params;
			last_response.status.should == 302;
			last_response.header["Location"].should == "http://example.org/protected";
		end
	end
end
