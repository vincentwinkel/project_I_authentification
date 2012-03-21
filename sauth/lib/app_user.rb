class AppUser < ActiveRecord::Base
	#Links between users and apps tables
	belongs_to :app; #Foreign key (id_app)
	belongs_to :user; #Foreign key (id_user)
	
	#Delete for an app
	def self.delete_for_app(id)
		AppUser.find_all_by_id_app(id).each { |a|
			AppUser.delete(a.id);
		}
	end
	
	#Delete for a user
	def self.delete_for_user(id)
		AppUser.find_all_by_id_user(id).each { |a|
			AppUser.delete(a.id);
		}
	end
	
	#Get apps for a user
	def self.get_apps_for_user(id)
		tab=Hash.new;
		AppUser.find_all_by_id_user(id).each { |au|
			app=Application.find_by_id(au.id_app);
			if (!app.nil?) then
				tab[app.id]=[app.name,app.url];
			else
				tab[au.id_app]=[nil,nil];
			end
		}
		tab;
	end
	
	#Get users for an app
	def self.get_users_for_app(id)
		tab=Hash.new;
		AppUser.find_all_by_id_app(id).each { |au|
			user=User.find_by_id(au.id_user);
			if (!user.nil?) then
				tab[user.id]=user.login;
			else
				tab[au.id_user]=nil;
			end
		}
		tab;
	end
	
	#Check if attributes are correctly defined
	validates :id_app, :presence => true;
	validates :id_app, :numericality => { :only_integer => true };
	validates :id_user, :presence => true;
	validates :id_user, :numericality => { :only_integer => true };
end
