class Application < ActiveRecord::Base
	attr_accessor :encode;
	attr_reader :url;
	
	#Constructor
	def initialize
		super;
		@encode=Digest::SHA1.new; #SHA1 object instance
	end
	
	#Url correction
	def url=(url)
		@url=(url[0,"http://".length] == "http://")?url:("http://" + url);
	end
	
	#Check if attributes are correctly defined
	validates :name, :presence => true;
	validates :url, :format => { :with => /^http:\/\/[^\s]+$/i, :on => :create };
end
