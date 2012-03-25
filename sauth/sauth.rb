ENV["RACK_ENV"]="development";

require 'sinatra';
require 'active_record';
require 'logger';
require_relative 'database';
require_relative 'lib/user';
require_relative 'lib/application';
require_relative 'lib/app_user';

#Cookies
use Rack::Session::Cookie, :key => "s_user", :expire_after => (60*60*24);

###########################
# Attributes and constants
###########################
set :form_values, Hash.new; #Form values (to keep corrects values if error(s) occurred)
set :form_errors, Hash.new; #Form errors (ex: input empty)
set :s_apps, Hash.new; #Session apps (apps the current session uses)
set :s_apps_admin, Hash.new; #Session apps admin (apps the current session is admin)
set :origin, ""; #url+origin for external apps connection
set :aid, 0; #app ID for external apps connection

set :ERROR_FORM_ANY_LOGIN, "Pseudonyme manquant";
set :ERROR_FORM_BAD_LOGIN, "Pseudonyme indisponible";
set :ERROR_FORM_NO_LOGIN, "Pseudonyme inexistant";
set :ERROR_FORM_ANY_PASS, "Mot de passe manquant";
set :ERROR_FORM_BAD_PASS_CONFIRM, "Mauvaise confirmation";
set :ERROR_FORM_ANY_NAME, "Nom manquant";
set :ERROR_FORM_BAD_NAME, "Nom indisponible et / ou";
set :ERROR_FORM_ANY_URL, "Url manquante (http://votre_application)";
set :ERROR_FORM_BAD_URL, "Url indisponible";

set :logger, Logger.new(File.dirname(__FILE__) + "/logs/raw","weekly"); #Logs
#Disable logs for tests
settings.logger.level=(ENV["RACK_ENV"] == "test")?(Logger::DEBUG):(Logger::WARN);

###########################
# Helpers
###########################
helpers do
  #Debug
  def dump(data)
    print "\n##### #{data} #####\n";
  end
  
  #Empty string test
  def is_empty(data)
    ((data.nil?) || (data.empty?));
  end
  
  #Clear form hashmaps
  def clearFormHash
    settings.form_values.clear;
    settings.form_errors.clear;
  end
  
  #Create a user session
  def create_session(login)
    session[:s_user]=login;
    u=User.find_by_login(login);
    session[:s_id]=u.id;
  end
  
  #Destroy current session
  def destroy_session
    session[:s_user]=nil;
    session[:s_id]=nil;
  end
  
  #Setting external app
  def set_external_app(origin,aid)
    settings.origin=origin;
    settings.aid=aid.to_i;
  end
  
  #Set used apps for a user
  def use_apps(id)
    settings.s_apps.replace(AppUser.get_apps_for_user(id));
    settings.s_apps_admin.replace(Application.get_apps_for_admin(id));
  end
  
  #Return current user name
  def user_name
    session[:s_user];
  end
  
  #Return current user ID
  def user_id
    session[:s_id];
  end
  
  #Return true if user session exists, else false
  def is_connected?
    user_name; #|| eventual future cookies
  end
  
  #Check a result of a session form (conf = true if password_conf is given)
  def checkSessionForm(params,conf)
    login=params[:user][:login];
    password=params[:user][:password];
    password_conf=params[:password_confirmation];
    error=false; #true if an error occurred, else false
    clearFormHash;
    if (is_empty(login)) then
      settings.form_errors[:login]=settings.ERROR_FORM_ANY_LOGIN;
      error=true;
    else
      settings.form_values[:login]=login;
    end
    if (is_empty(password)) then
      settings.form_errors[:password]=settings.ERROR_FORM_ANY_PASS;
      error=true;
    elsif ((conf == true) && ((is_empty(password_conf)) || (password != password_conf))) then
      settings.form_errors[:password]="";
      settings.form_errors[:password_confirmation]=settings.ERROR_FORM_BAD_PASS_CONFIRM;
      error=true;
    end
    error;
  end
  
  #Check a result of an app form
  def checkAppForm(params)
    name=params[:application][:name];
    url=params[:application][:url];
    error=false; #true if an error occurred, else false
    clearFormHash;
    if (is_empty(name)) then
      settings.form_errors[:name]=settings.ERROR_FORM_ANY_NAME;
      error=true;
    else
      settings.form_values[:name]=name;
    end
    if (is_empty(url)) then
      settings.form_errors[:url]=settings.ERROR_FORM_ANY_URL;
      error=true;
    else
      settings.form_values[:url]=url;
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
    clearFormHash;
    erb :"apps/new";
  end
end

#User inscription link
get %r{^/users/new$}i do
  #If session exists, redirect to protected area
  if (is_connected?) then
    redirect "/users/#{user_id}";
  #Else, print user inscription page
  else
    clearFormHash;
    erb :"users/new";
  end
end

#Protected area link
get %r{^/users/(\d+)$}i do |id|
  id=id.to_i;
  #If session exists, print protected area
  if ((is_connected?) && (id == user_id)) then
    #Check session apps
    use_apps(id);
    #Print protected area
    erb :"users/profile";
  #Else, redirect to connection page
  else
    redirect "/sessions/new";
  end
end

#User connection link
get %r{^/sessions/new$}i do
  #If session exists, redirect to protected area
  if (is_connected?) then
    redirect "/users/#{user_id}";
  #Else, print connection page
  else
    clearFormHash;
    set_external_app(nil,0);
    erb :"sessions/new";
  end
end

##### From an external app

#User connection link from an other app
get %r{^/(\d+)/sessions/new$}i do |aid|
  a=Application.find_by_id(aid);
  #If app doesn't exist, print error
  if (!a) then
    erb :"apps/error";
  #Else, continue procedure
  else
    if (is_connected?) then
      AppUser.add_user_for_app(a.id,user_id);
      redirect "#{a.url}#{params[:ref]}?login=#{user_name}&key=sauth4567";
    #Else, print the connection page
    else
      clearFormHash;
      set_external_app("#{a.url}#{params[:ref]}",a.id);
      erb :"sessions/new";
    end
  end
end

##### Default redirection

#By default, redirect to connection page
get "/*" do
  redirect "/sessions/new";
end

###########################
# DELETE requests
###########################

#App destroy link
delete %r{^/apps/(\d+)$}i do |id|
  id=id.to_i;
  #If session exists, delete the app
  if ((is_connected?) && (id > 0)) then
    Application.delete(id);
    AppUser.delete_for_app(id);
  end
  #Redirect to protected area
  redirect "/users/#{user_id}";
end

#Deconnection link
delete %r{^/sessions/(\d+)$}i do |id|
  #If session exists, delete it
  if ((is_connected?) && (id.to_i == user_id)) then
    settings.logger.info("[Disconnection] User \##{user_id}: #{user_name}");
    destroy_session;
  end
  #Redirect to connection page
  redirect "/sessions/new";
end

###########################
# POST requests
###########################

#Inscription app form
post %r{^/apps$}i do
  #If session doesn't exist, redirect to connection page
  if (!is_connected?) then
    redirect "/sessions/new";
    return;
  end
  #Check form errors
  error=checkAppForm(params);
  #If error occurred, print page
  if (error) then
    erb :"apps/new";
  #Else if any error, check the validity of the app
  else
    a=Application.new(params[:application]);
    a.admin=user_id;
    #If it's good, validate the add
    if (ActiveRecordHooks.valid?(a)) then
      ActiveRecordHooks.save(a);
      settings.logger.info("[New app] App \##{a.id}: #{a.name} (#{a.url})");
      redirect "/users/#{user_id}";
    #Else, the app name or app url already exists
    else
      settings.form_errors[:name]=settings.ERROR_FORM_BAD_NAME;
      settings.form_errors[:url]=settings.ERROR_FORM_BAD_URL;
      erb :"apps/new";
    end
  end
end

#Inscription form
post %r{^/users$}i do
  #Check form errors
  error=checkSessionForm(params,true);
  #If error occurred, print page
  if (error) then
    erb :"users/new";
  #Else if any error, check the validity of the account
  else
    u=User.new(params[:user]);
    #If it's good, validate the inscription
    if (ActiveRecordHooks.valid?(u)) then
      ActiveRecordHooks.save(u);
      create_session(u.login);
      settings.logger.info("[Inscription] User \##{user_id}: #{user_name}");
      redirect "/users/#{user_id}";
    #Else, the login already exists
    else
      settings.form_errors[:login]=settings.ERROR_FORM_BAD_LOGIN;
      erb :"users/new";
    end
  end
end

#Connection form
post %r{^/sessions$}i do
  set_external_app(nil,0);
  connectResponse(params,"/users/USER_ID",true);
end
post %r{^/apps/sessions$}i do
  set_external_app(params[:origin],params[:aid]);
  connectResponse(params,"#{params[:origin]}?login=USER_LOGIN&key=sauth4567",false);
end

def connectResponse(params,ok_url,local)
  #Check form errors
  error=checkSessionForm(params,false);
  #If error occurred, print page
  if (error) then
    erb :"sessions/new";
  #Else if any error, check the validity of the account
  else
    u=User.find_by_login(params[:user][:login]);
    #If it's good, validate the connection
    if ((u) && (u.has_password(params[:user][:password]))) then
      create_session(params[:user][:login]);
      if (local) then
        settings.logger.info("[Local connection] User \##{u.id}: #{u.login}");
        ok_url["USER_ID"]=user_id.to_s;
      else
        settings.logger.info("[External connection] User \##{u.id}: #{u.login}");
        ok_url["USER_LOGIN"]=user_name;
        AppUser.add_user_for_app(params[:aid].to_i,u.id);
      end
      redirect ok_url;
    #Else, the login no exists
    else
      settings.form_errors[:login]=settings.ERROR_FORM_NO_LOGIN;
      erb :"sessions/new";
    end
  end
end
