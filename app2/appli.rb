require "sinatra";
require "digest/sha1";

use Rack::Session::Cookie, :key => "a_user2", :expire_after => (60*60*24);

set :port, 9292; #App port
set :appID, 2; #App ID for sauth

set :stylesheet, "<link rel=\"stylesheet\" type=\"text/css\" href=" \
  "\"http://localhost:#{settings.port}/style.css\" />"; #Stylesheet

helpers do
  #Empty string test
  def is_empty(data)
    ((data.nil?) || (data.empty?));
  end
  
  #Return true if user session exists, else false
  def is_connected?
    session[:a_user2];
  end
end

#Stylsheets
get %r{^/(\w+).css$}i do |file|
  scss :"#{file}";
end

#Home page
get "/" do
  #If session exists, redirect to protected area
  if (is_connected?) then
    #Print protected area
    redirect "/protected";
  #Else, redirect to the home page
  else
    erb :"index";
  end
end

#Protected area
get %r{^/protected$}i do
  #If GET params exist, redirect to protected area without them (security)
  if ((!is_empty(params[:login])) && (params[:key] == "sauth4567")) then
      session[:a_user2]=params[:login];
      redirect "/protected";
  #If session exists, print protected area
  elsif (is_connected?) then
    erb :"protected";
  #Else, redirect to the home page
  else
    redirect "/";
  end
end

#Deconnection link
get %r{^/sessions/destroy$}i do
  #If session exists, delete it
  if (is_connected?) then
    session[:a_user2]=nil;
  end
  #Redirect to connection page
  redirect "/";
end
