require_relative 'active_record_hooks';

class Application < ActiveRecord::Base
  include ActiveRecordHooks;
  
  #Link with apps table
  has_many :app_users;
  has_many :users, :through => :app_users;#, :dependent => :delete_all;
  
  #Url correction
  def url=(url)
    write_attribute(:url,(url[0,"http://".length] == "http://")?url:("http://" + url));
  end
  
  #Get the apps created by a user
  def self.get_apps_for_admin(id)
    tab=Hash.new;
    Application.find_all_by_admin(id).each { |a|
      tab[a.id]=[a.name,a.url];
    }
    tab;
  end
  
  #Check if attributes are correctly defined
  validates :name, :presence => true;
  validates :name, :uniqueness => true;
  validates :url, :uniqueness => true;
  validates :url, :format => { :with => /^http:\/\/[^\s]+$/i, :on => :create };
  validates :admin, :presence => true;
  validates :admin, :numericality => { :only_integer => true };
end
