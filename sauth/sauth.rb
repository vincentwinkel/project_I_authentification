require 'sinatra';

$: << File.join(File.dirname(__FILE__),"middleware");
require 'auth_middleware';
require 'active_record';
require_relative 'database';
require_relative 'lib/user';
require_relative 'lib/application';
require_relative 'lib/app_user';

use RackCookieSession;
use RackSession;

#set :port, 9494; #For apps

#Attributes and constants
set :form_values, Hash.new; #Form values (to keep corrects values if error(s) occurred)
set :form_errors, Hash.new; #Form errors (ex: input empty)

set :ERROR_FORM_ANY_LOGIN, "Pseudonyme manquant";
set :ERROR_FORM_BAD_LOGIN, "Pseudonyme indisponible";
set :ERROR_FORM_NO_LOGIN, "Pseudonyme inexistant";
set :ERROR_FORM_ANY_PASS, "Mot de passe manquant";
set :ERROR_FORM_BAD_PASS_CONFIRM, "Mauvaise confirmation";

set :stylesheet, "<link rel=\"stylesheet\" type=\"text/css\" href=" \
	"\"http://localhost:#{settings.port}/style.css\" />"; #Stylesheet

###########################
# GET requests
###########################

##### From the auth site

#Stylsheets
get %r{^/(\w+).css$}i do |file|
	scss :"#{file}";
end

#App inscription link
get %r{^/apps/new$}i do
	erb :"/apps/new";
end

#User inscription link
get %r{^/register$}i do
	#If session exists, redirect to protected area
	if (session.keys.include? env["rack.session.id"]) then
		redirect "/protected";
	#Else, print user inscription page
	else
		erb :"/register", :locals => {:form_errors => Hash.new,:form_values => Hash.new};
	end
end

#Connection link
get %r{^/sessions/new$}i do
	#If session exists, redirect to protected area
	if (session.keys.include? env["rack.session.id"]) then
		redirect "/protected";
	#Else, print connection page
	else
		erb :"/sessions/new";
	end
end

#Protected area link
get %r{^/protected$}i do
	#If session exists, redirect to protected area
	if (session.keys.include? env["rack.session.id"]) then
		erb :"/protected";
	#Else, print connection page
	else
		redirect "/sessions/new";
	end
end

#Deconnection link
get %r{^/sessions/id$}i do
	#If session exists, delete it
	if (session.keys.include? env["rack.session.id"]) then
		session.delete(env["rack.session.id"]);
	end
	#Redirect to connection page
	redirect "/sessions/new";
end

##### From an external app

#Connection link from an other app
get %r{^/(\d+)/sessions/new/ref=(.+)$}i do |app,ref|
	"lol : "+app+" "+ref;
end

##### Default redirection

#By default, redirect to connection page
get "/*" do
	redirect "/sessions/new";
end

###########################
# POST requests
###########################

##### From the auth site

#Inscription form
post %r{^/register$}i do
	error=false; #true if an error occurred, else false
	#Check form errors
	settings.form_values.clear;
	settings.form_errors.clear;
	if ((params["login"].nil?) || (params["login"].empty?)) then
		settings.form_errors["login"]=settings.ERROR_FORM_ANY_LOGIN;
		error=true;
	else
		settings.form_values["login"]=params["login"];
	end
	if ((params["password"].nil?) || (params["password"].empty?)) then
		settings.form_errors["password"]=settings.ERROR_FORM_ANY_PASS;
		error=true;
	else
		#No keep password for security
		if ((params["password_confirmation"].nil?) || (params["password_confirmation"].empty?) \
			|| (params["password"] != params["password_confirmation"])) then
			settings.form_errors["password"]="";
			settings.form_errors["password_confirmation"]=settings.ERROR_FORM_BAD_PASS_CONFIRM;
			error=true;
		else
			#No keep password confirmation for security
		end
	end
	#If error occurred, print page
	if (error) then
		erb :"/register", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	#Else if any error, check the validity of the account
	else
		u=User.new;
		u.login=params["login"];
		u.password=params["password"];
		#If it's good, validate the inscription
		if (u.valid?) then
			u.save;
			session[env["rack.session.id"]]=params["login"];
			redirect "/protected";
		#Else, the login already exists
		else
			settings.form_errors["login"]=settings.ERROR_FORM_BAD_LOGIN;
			erb :"/register", :locals => {
				:form_errors => settings.form_errors,
				:form_values => settings.form_values
			};
		end
	end
end

#Connection form
post %r{^/sessions/new$}i do
	error=false; #true if an error occurred, else false
	#Check form errors
	settings.form_values.clear;
	settings.form_errors.clear;
	if ((params["login"].nil?) || (params["login"].empty?)) then
		settings.form_errors["login"]=settings.ERROR_FORM_ANY_LOGIN;
		error=true;
	else
		settings.form_values["login"]=params["login"];
	end
	if ((params["password"].nil?) || (params["password"].empty?)) then
		settings.form_errors["password"]=settings.ERROR_FORM_ANY_PASS;
		error=true;
	else
		#No keep password for security
	end
	#If error occurred, print page
	if (error) then
		erb :"/sessions/new", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	#Else if any error, check the validity of the account
	else
		u=User.find_by_login(params["login"]);
		#If it's good, validate the inscription
		if ((u) && (u.password == User.new.encode.hexdigest(params["password"]))) then
			session[env["rack.session.id"]]=params["login"];
			redirect "/protected";
		#Else, the login no exists
		else
			settings.form_errors["login"]=settings.ERROR_FORM_NO_LOGIN;
			erb :"/register", :locals => {
				:form_errors => settings.form_errors,
				:form_values => settings.form_values
			};
		end
	end
end

##### From an external app
