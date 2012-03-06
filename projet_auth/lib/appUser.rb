class AppUser < ActiveRecord::Base
	#Check if attributes are correctly defined
	validates :id_app, :numericality => true;
	validates :id_user, :numericality => true;
end