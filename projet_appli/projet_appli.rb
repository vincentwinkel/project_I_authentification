require "sinatra"

$: << File.join(File.dirname(__FILE__),"middleware")
require "my_middleware"

use RackCookieSession
use RackSession

def storeReqest(req)
	request.session["history"] ||= []
	request.session["history"] << [request.request_method,request.path_info, request.query_string]
end

#Requêtes GET
get "/*" do
	#Historique des requêtes
	#result = "cookie= #{request.cookies.inspect}</br>"
	#result << "rack.session.id=#{env["rack.session.id"]}</br>"
	#result << "rack.session=#{env["rack.session"].inspect}</br>"
	
	#Page de connexion
	if (request.path_info == "/sessions/new") then
		if (session.keys.include? env["rack.session.id"]) then
			redirect "/protected";
		else
			erb :"/sessions/new";
		end
	else
		if ((request.path_info == "/protected") && (session.keys.include? env["rack.session.id"])) then
			erb :"/protected";
		else
			if (request.path_info == "/sessions/id") then
				session.delete(env["rack.session.id"]);
				redirect "/sessions/new";
			else
				redirect "/sessions/new";
			end
		end
	end
end

#Requêtes POST
post "/*" do
	if ((request.path_info == "/sessions") && (params["login"] == "titi") && (params["password"] == "toto")) then
		session[env["rack.session.id"]]=params["login"];
		redirect "/protected";
	else
		redirect "/sessions/new";
	end
end
