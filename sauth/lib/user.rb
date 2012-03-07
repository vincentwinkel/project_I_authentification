require 'digest/sha1';

class User < ActiveRecord::Base
	#Attributes
	attr_accessor :encode;
	
	#Link with apps table
	has_many :app_users;
	has_many :applications, :through => :app_users;
	
	#Constructor
	def initialize
		super;
		@encode=Digest::SHA1.new; #SHA1 object instance
	end
	
	#Password encryption
	def password=(mdp)
		if ((!mdp.nil?) && (!mdp.empty?)) then
			write_attribute(:password,@encode.hexdigest(mdp).inspect[1,40]);
		end
	end
	
	#Check if attributes are correctly defined
	validates :login, :presence => true;
	validates :password, :format => { :with => /^[a-z0-9]{40}$/i, :on => :create };
end
