class AppUser < ActiveRecord::Base
  #Links between users and apps tables
  belongs_to :application; #Foreign key (application_id)
  belongs_to :user; #Foreign key (user_id)
  
  #Delete for an app
  def self.delete_for_app(id)
    self.find_all_by_application_id(id).each { |a|
      self.delete(a.id);
    }
  end
  
  #Delete for a user
  def self.delete_for_user(id)
    self.find_all_by_user_id(id).each { |a|
      self.delete(a.id);
    }
  end
  
  #Get apps for a user
  def self.get_apps_for_user(id)
    tab=Hash.new;
    self.find_all_by_user_id(id).each { |au|
      app=Application.find_by_id(au.application_id);
      if (!app.nil?) then
        tab[app.id]=[app.name,app.url];
      else
        tab[au.application_id]=[nil,nil];
      end
    }
    tab;
  end
  
  #Get users for an app
  def self.get_users_for_app(id)
    tab=Hash.new;
    self.find_all_by_application_id(id).each { |au|
      user=User.find_by_id(au.user_id);
      if (!user.nil?) then
        tab[user.id]=user.login;
      else
        tab[au.user_id]=nil;
      end
    }
    tab;
  end
  
  #Add user for app if it don't exists
  def self.add_user_for_app(application_id,user_id)
    if (!self.exists?(:application_id => application_id,:user_id => user_id)) then
      self.create({:application_id => application_id,:user_id => user_id});
    end
  end
  
  #Check if attributes are correctly defined
  validates :application_id, :presence => true;
  validates :application_id, :numericality => {:only_integer => true};
  validates :user_id, :presence => true;
  validates :user_id, :numericality => {:only_integer => true};
end
