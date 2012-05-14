require 'digest/sha1';
#require_relative 'active_record_hooks';

class User < ActiveRecord::Base
  #include ActiveRecordHooks;
  
  #Link with apps table
  has_many :app_users;
  has_many :applications, :through => :app_users;
  
  #Password setting
  def password=(mdp)
    if ((!mdp.nil?) && (!mdp.empty?)) then
      write_attribute(:password,User.encrypt(mdp).inspect[1,40]);
    end
  end
  
  #Password encryption
  def self.encrypt(mdp)
    if ((!mdp.nil?) && (!mdp.empty?)) then
      Digest::SHA1.hexdigest(mdp);
    end
  end
  
  #Compare password
  def has_password(mdp)
    (read_attribute(:password) == User.encrypt(mdp));
  end
  
  #Check if attributes are correctly defined
  validates :login, :presence => true;
  validates :login, :uniqueness => {:case_sensitive => false};
  validates :password, :format => {:with => /^[a-z0-9]{40}$/i,:on => :create};
end
