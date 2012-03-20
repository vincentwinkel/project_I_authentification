require 'sinatra';

require 'active_record';
require_relative 'database';
require_relative 'lib/user';
require_relative 'lib/application';
require_relative 'lib/app_user';

enable :sessions;

#Attributes and constants
set :form_values, Hash.new; #Form values (to keep corrects values if error(s) occurred)
set :form_errors, Hash.new; #Form errors (ex: input empty)
set :s_apps, Hash.new; #Session apps (apps the current session uses)
set :s_apps_admin, Hash.new; #Session apps admin (apps the current session is admin)
set :origin, ""; #url+origin for external apps connection
set :aid, ""; #app ID for external apps connection

set :ERROR_FORM_ANY_LOGIN, "Pseudonyme manquant";
set :ERROR_FORM_BAD_LOGIN, "Pseudonyme indisponible";
set :ERROR_FORM_NO_LOGIN, "Pseudonyme inexistant";
set :ERROR_FORM_ANY_PASS, "Mot de passe manquant";
set :ERROR_FORM_BAD_PASS_CONFIRM, "Mauvaise confirmation";
set :ERROR_FORM_ANY_NAME, "Nom manquant";
set :ERROR_FORM_BAD_NAME, "Nom indisponible";
set :ERROR_FORM_ANY_URL, "Url manquante (http://votre_application)";

set :stylesheet, "<link rel=\"stylesheet\" type=\"text/css\" href=" \
	"\"http://localhost:#{settings.port}/style.css\" />"; #Stylesheet

helpers do
	#Debug
	def dump(data)
		print "\n##### #{data} #####\n";
	end
	
	#Empty string test
	def is_empty(data)
		return ((data.nil?) || (data.empty?));
	end
	
	#Create a user session
	def create_session(login)
		session["s_user"]=login;
		u=User.find_by_login(login);
		session["s_id"]=u.id;
		response.set_cookie("sauth",{
			:value => login,
			:expires => Time.parse((Time.now+(60*60*24)).to_s),:path => "/"
		});
	end
	
	#Destroy a user session
	def destroy_session
		session.delete("s_user");
		session.delete("s_id");
		response.set_cookie("sauth",{:value => "",:expires => Time.at(0),:path => "/"});
	end
	
	#Returns true if user session exists, else false
	def is_connected?
		((session.keys.include? "s_user") || (!is_empty(request.cookies["s_user"])));
	end
	
	#Check a result of a session form (conf = true if password_conf is given)
	def checkSessionForm(login,password,password_conf,conf)
		error=false; #true if an error occurred, else false
		settings.form_values.clear;
		settings.form_errors.clear;
		if (is_empty(login)) then
			settings.form_errors["login"]=settings.ERROR_FORM_ANY_LOGIN;
			error=true;
		else
			settings.form_values["login"]=login;
		end
		if (is_empty(password)) then
			settings.form_errors["password"]=settings.ERROR_FORM_ANY_PASS;
			error=true;
		else
			#No keep password for security
			if ((conf == true) && ((is_empty(password_conf)) \
				|| (password != password_conf))) then
				settings.form_errors["password"]="";
				settings.form_errors["password_confirmation"]=settings.ERROR_FORM_BAD_PASS_CONFIRM;
				error=true;
			else
				#No keep password confirmation for security
			end
		end
		error;
	end
	
	#Check a result of an app form
	def checkAppForm(name,url)
		error=false; #true if an error occurred, else false
		settings.form_values.clear;
		settings.form_errors.clear;
		if (is_empty(name)) then
			settings.form_errors["name"]=settings.ERROR_FORM_ANY_NAME;
			error=true;
		else
			settings.form_values["name"]=name;
		end
		if (is_empty(url)) then
			settings.form_errors["url"]=settings.ERROR_FORM_ANY_URL;
			error=true;
		else
			settings.form_values["url"]=url;
		end
		error;
	end
end

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
	#If session donesn't exist, redirect to connection page
	if (!is_connected?) then
		redirect "/sessions/new";
	#Else, print app inscription page
	else
		erb :"/apps/new", :locals => {:form_errors => Hash.new,:form_values => Hash.new};
	end
end

#App destroy link
get %r{^/apps/destroy/(\d+)$}i do |id|
	#If session exists, delete the app
	if ((is_connected?) && (Integer(id) > 0)) then
		Application.delete(id);
		AppUser.delete_for_app(id);
	end
	#Redirect to protected area
	redirect ("/users/" + session["s_id"].to_s);
end

#User inscription link
get %r{^/users/new$}i do
	#If session exists, redirect to protected area
	if (is_connected?) then
		redirect ("/users/" + session["s_id"].to_s);
	#Else, print user inscription page
	else
		erb :"/users/new", :locals => {:form_errors => Hash.new,:form_values => Hash.new};
	end
end

#Protected area link
get %r{^/users/(\d+)$}i do |id|
	#If session exists, print protected area
	if ((is_connected?) && (id == session["s_id"].to_s)) then
		#Check session apps
		settings.s_apps.replace(AppUser.get_apps_for_user(id));
		settings.s_apps_admin.replace(Application.get_apps_for_admin(id));
		#Print protected area
		erb :"/users/profile";
	#Else, redirect to connection page
	else
		redirect "/sessions/new";
	end
end

#User destroy link
get %r{^/users/destroy/(\d+)$}i do |id|
	#If session exists, delete the app
	if ((is_connected?) && (Integer(id) > 0)) then
		Application.delete(id);
		AppUser.delete_for_app(id);
	end
	#Redirect to connection page
	redirect ("/sessions/new");
end

#User connection link
get %r{^/sessions/new$}i do
	#If session exists, redirect to protected area
	if (is_connected?) then
		redirect ("/users/" + session["s_id"].to_s);
	#Else, print connection page
	else
		erb :"/sessions/new", :locals => {:form_errors => Hash.new,:form_values => Hash.new};
	end
end

#Deconnection link
get %r{^/sessions/destroy$}i do
	#If session exists, delete it
	if (is_connected?) then
		destroy_session;
	end
	#Redirect to connection page
	redirect "/sessions/new";
end

##### From an external app

#Connection link from an other app
get %r{^/(\d+)/sessions/new$}i do |id_app|
	a=Application.find_by_id(id_app);
	#If any app exists, print error
	if ((a.nil?) || (is_empty(params["ref"]))) then
		erb :"apps/error";
	#Else, continue procedure
	else
		if (is_connected?) then
			redirect a.url+params["ref"] + "?key=sauth4567";
		#Else, print the connection page
		else
			settings.origin=a.url+params["ref"];
			settings.aid=a.id;
			erb :"sessions/new", :locals => {:form_errors => Hash.new,:form_values => Hash.new};
		end
	end
end

##### Default redirection

#By default, redirect to connection page
get "/*" do
	redirect "/sessions/new";
end

###########################
# POST requests
###########################

#Inscription app form
post %r{^/apps$}i do
	#If session doesn't exist, redirect to connection page
	if (!is_connected?) then
		redirect "sessions/new";
		return;
	end
	#Check form errors
	error=checkAppForm(params["name"],params["url"]);
	#If error occurred, print page
	if (error) then
		erb :"/apps/new", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	#Else if any error, check the validity of the account
	else
		name=params["name"].downcase;
		a=Application.new({:name => name,:url => params["url"],:admin => session["s_id"]});
		#If it's good, validate the inscription
		if (a.valid?) then
			a.save;
			redirect ("/users/" + session["s_id"].to_s);
		#Else, the login already exists
		else
			settings.form_errors["name"]=settings.ERROR_FORM_BAD_NAME;
			erb :"/apps/new", :locals => {
				:form_errors => settings.form_errors,
				:form_values => settings.form_values
			};
		end
	end
end

#Inscription form
post %r{^/users$}i do
	#Check form errors
	error=checkSessionForm(params["login"],params["password"],params["password_confirmation"],true);
	#If error occurred, print page
	if (error) then
		erb :"/users/new", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	#Else if any error, check the validity of the account
	else
		login=params["login"].downcase;
		u=User.new({:login => login,:password => params["password"]});
		#If it's good, validate the inscription
		if (u.valid?) then
			u.save;
			create_session(login);
			redirect ("/users/" + session["s_id"].to_s);
		#Else, the login already exists
		else
			settings.form_errors["login"]=settings.ERROR_FORM_BAD_LOGIN;
			erb :"/users/new", :locals => {
				:form_errors => settings.form_errors,
				:form_values => settings.form_values
			};
		end
	end
end

#Connection form
post %r{^/sessions$}i do
	connectResponse(params,"/users/USER_ID",true);
end
post %r{^/apps/sessions$}i do
	settings.origin=params["origin"];
	settings.aid=params["aid"];
	connectResponse(params,params["origin"] + "?key=sauth4567",false);
end

def connectResponse(params,ok_url,local)
	#Check form errors
	error=checkSessionForm(params["login"],params["password"],nil,false);
	#If error occurred, print page
	if (error) then
		erb "/sessions/new", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	#Else if any error, check the validity of the account
	else
		login=params["login"].downcase;
		u=User.find_by_login(login);
		#If it's good, validate the connection
		if ((u) && (u.password == User.encrypt(params["password"]))) then
			create_session(login);
			if (local) then
				ok_url["USER_ID"]=session["s_id"].to_s;
			else
				au=AppUser.create({:id_app => params["aid"],:id_user => u.id});
			end
			redirect ok_url;
		#Else, the login no exists
		else
			settings.form_errors["login"]=settings.ERROR_FORM_NO_LOGIN;
			erb :"/sessions/new", :locals => {
				:form_errors => settings.form_errors,
				:form_values => settings.form_values
			};
		end
	end
end
