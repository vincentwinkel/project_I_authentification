require "sinatra"

$: << File.join(File.dirname(__FILE__),"middleware")
require "auth_middleware"

use RackCookieSession
use RackSession

def storeReqest(req)
	request.session["history"] ||= [];
	request.session["history"] << [request.request_method,request.path_info, request.query_string];
end

###########################
# GET requests
###########################

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
		erb :"/register";
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

#Connection link from an other app
get %r{^/(\d+)/sessions/new/ref=(.+)$}i do |app,ref|
	"lol : "+app+" "+ref;
end

#Page de zone protégée
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

#By default, redirect to connection page
get "/*" do
	redirect "/sessions/new";
end

###########################
# POST requests
###########################

#Inscription form
post %r{^/register/?$}i do
	if ((params["login"] == "titi") && (params["password"] == "toto")) then
		session[env["rack.session.id"]]=params["login"];
		redirect "/protected";
	else
		redirect "/sessions/new";
	end
end

#Connection form
post %r{^/sessions/?$}i do
	if ((params["login"] == "titi") && (params["password"] == "toto")) then
		session[env["rack.session.id"]]=params["login"];
		redirect "/protected";
	else
		redirect "/sessions/new";
	end
end
