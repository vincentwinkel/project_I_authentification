class Person < ActiveRecord::Base
	#Check if login is correctly explicited
	validates :login, :presence => true;
	#Check if password is correctly explicited
	validates :password, :presence => true;
end
