class StackSessions
	attr_accessor :session;
	
	#Create a user session
	def create_session(login)
		session["suser"]=login;
		response.set_cookie("sauth",{
			:value => login,
			:expires => Time.parse((Time.now+(60*60*24)).to_s),:path => "/"
		});
	end
	#Destroy a user session
	def destroy_session
		session.delete("suser");
		response.set_cookie("sauth",{:value => "",:expires => Time.at(0),:path => "/"});
	end
	#Returns true if user session exists, else false
	def is_connected?
		((session.keys.include? "suser") \
		|| ((!request.cookies["suser"].nil?) && (!request.cookies["suser"].empty?)));
	end
end
