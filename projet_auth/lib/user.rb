require 'digest/sha1';

class User < ActiveRecord::Base
	attr_accessor :encode;
	
	#Constructor
	def initialize
		super;
		@encode=Digest::SHA1.new; #SHA1 object instance
	end
	
	#Password encryption
	def password=(mdp)
		write_attribute(:password,@encode.hexdigest(mdp)); 
	end
	
	#Check if attributes are correctly defined
	validates :login, :presence => true;
	validates :password, :format => { :with => /^[a-z0-9]{32}$/i, :on => :create };
end
