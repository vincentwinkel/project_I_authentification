class AppUser < ActiveRecord::Base
	#Links between users and apps tables
	belongs_to :app #Foreign key (id_app)
	belongs_to :user #Foreign key (id_user)
	
	#Check if attributes are correctly defined
	validates :id_app, :numericality => { :only_integer => true };
	validates :id_user, :numericality => { :only_integer => true };
end
