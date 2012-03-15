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
set :origin, ""; #url+orgin for external apps connection

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
		print "##### #{data} #####\n";
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
		((session.keys.include? "s_user") \
		|| ((!request.cookies["s_user"].nil?) && (!request.cookies["s_user"].empty?)));
	end
	
	#Check a result of a session form (conf = true if password_conf is given)
	def checkSessionForm(login,password,password_conf,conf)
		error=false; #true if an error occurred, else false
		settings.form_values.clear;
		settings.form_errors.clear;
		if ((login.nil?) || (login.empty?)) then
			settings.form_errors["login"]=settings.ERROR_FORM_ANY_LOGIN;
			error=true;
		else
			settings.form_values["login"]=login;
		end
		if ((password.nil?) || (password.empty?)) then
			settings.form_errors["password"]=settings.ERROR_FORM_ANY_PASS;
			error=true;
		else
			#No keep password for security
			if ((conf == true) && ((password_conf.nil?) || (password_conf.empty?) \
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
		if ((name.nil?) || (name.empty?)) then
			settings.form_errors["name"]=settings.ERROR_FORM_ANY_NAME;
			error=true;
		else
			settings.form_values["name"]=name;
		end
		if ((url.nil?) || (url.empty?)) then
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
		AppUser.find_all_by_id_app(id).each { |a|
			AppUser.delete(a.id);
		}
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
		settings.s_apps.clear;
		settings.s_apps_admin.clear;
		au=AppUser.find_all_by_id_user(id).each { |a|
			app=Application.find_by_id(a.id_app);
			settings.s_apps[app.id]=[app.name,app.url];
		}
		a=Application.find_all_by_admin(id).each { |a|
			settings.s_apps_admin[a.id]=[a.name,a.url];
		}
		#Print protected area
		erb :"/users/profile";
	#Else, redirect to connection page
	else
		redirect "/sessions/new";
	end
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
	#If any app exists, redirect to the origin website
	if (a.nil?) then
		request.inspect;#.headers["Location"];
	#Else, print the connection page
	else
		settings.origin=a.url+params["ref"];
		erb :"sessions/new", :locals => {:form_errors => Hash.new,:form_values => Hash.new};
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

##### From the auth site

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
		a=Application.new;
		a.name=name;
		a.url=params["url"];
		a.admin=session["s_id"];
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
		u=User.new;
		u.login=login;
		u.password=params["password"];
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
	#Check form errors
	error=checkSessionForm(params["login"],params["password"],nil,false);
	#If error occurred, print page
	if (error) then
		erb :"/sessions/new", :locals => {
			:form_errors => settings.form_errors,
			:form_values => settings.form_values
		};
	#Else if any error, check the validity of the account
	else
		login=params["login"].downcase;
		u=User.find_by_login(login);
		#If it's good, validate the inscription
		if ((u) && (u.password == User.new.encode.hexdigest(params["password"]))) then
			create_session(login);
			redirect ("/users/" + session["s_id"].to_s);
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

##### From an external app
