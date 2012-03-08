class Application < ActiveRecord::Base
	#Link with apps table
	has_many :app_users;
	has_many :users, :through => :app_users;
	
	#Url correction
	def url=(url)
		write_attribute(:url,(url[0,"http://".length] == "http://")?url:("http://" + url));
	end
	
	#Check if attributes are correctly defined
	validates :name, :presence => true;
	validates :name, :uniqueness => true;
	validates :url, :uniqueness => true;
	validates :url, :format => { :with => /^http:\/\/[^\s]+$/i, :on => :create };
end
