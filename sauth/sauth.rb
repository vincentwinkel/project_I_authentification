require 'sinatra';

$: << File.join(File.dirname(__FILE__),"middleware");
require 'auth_middleware';

use RackCookieSession;
use RackSession;

#set :port, 9494; #For apps

#Attributes and constants
set :form_values, Hash.new; #Form values (to keep corrects values if error(s) occurred)
set :form_errors, Hash.new; #Form errors (ex: input empty)

set :ERROR_FORM_ANY_LOGIN, "Pseudonyme manquant";
set :ERROR_FORM_ANY_PASS, "Mot de passe manquant";
set :ERROR_FORM_BAD_PASS_CONFIRM, "Mauvaise confirmation";

###########################
# GET requests
###########################

##### From the auth site

#App inscription link
get %r{^/apps/new/?$}i do
	erb :"/apps/new";
end

#User inscription link
get %r{^/register/?$}i do
	#If session exists, redirect to protected area
	if (session.keys.include? env["rack.session.id"]) then
		redirect "/protected";
	#Else, print user inscription page
	else
		erb :"/register", :locals => { :form_errors => Hash.new(),:form_values => Hash.new() };
	end
end

#Connection link
get %r{^/sessions/new/?$}i do
	#If session exists, redirect to protected area
	if (session.keys.include? env["rack.session.id"]) then
		redirect "/protected";
	#Else, print connection page
	else
		erb :"/sessions/new";
	end
end

#Protected area link
get %r{^/protected/?$}i do
	#If session exists, redirect to protected area
	if (session.keys.include? env["rack.session.id"]) then
		erb :"/protected";
	#Else, print connection page
	else
		redirect "/sessions/new";
	end
end

#Deconnection link
get %r{^/sessions/id/?$}i do
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
post %r{^/register/?$}i do
	if ((params["login"] == "titi") && (params["password"] == "toto") \
		&& (params["password_confirmation"] == "toto")) then
		session[env["rack.session.id"]]=params["login"];
		redirect "/protected";
	#Else, retry and show errors
	else
		#Check form errors
		settings.form_values.clear;
		settings.form_errors.clear;
		if ((params["login"].nil?) || (params["login"].empty?)) then
			settings.form_errors["login"]=settings.ERROR_FORM_ANY_LOGIN;
		else
			settings.form_values["login"]=params["login"];
		end
		if ((params["password"].nil?) || (params["password"].empty?)) then
			settings.form_errors["password"]=settings.ERROR_FORM_ANY_PASS;
		else
			#No keep password for security
			if ((params["password_confirmation"].nil?) || (params["password_confirmation"].empty?) \
				|| (params["password"] != params["password_confirmation"])) then
				settings.form_errors["password"]="";
				settings.form_errors["password_confirmation"]=settings.ERROR_FORM_BAD_PASS_CONFIRM;
			else
				#No keep password confirmation for security
			end
		end
		#Print page
		erb :"/register", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	end
end

#Connection form
post %r{^/sessions/?$}i do
	if ((params["login"] == "titi") && (params["password"] == "toto")) then
		session[env["rack.session.id"]]=params["login"];
		redirect "/protected";
	#Else, retry and show errors
	else
		redirect "/sessions/new";
	end
end

##### From an external app
