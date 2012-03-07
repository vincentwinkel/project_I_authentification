class CreateTableAppusers < ActiveRecord::Migration
  def up
    create_table :app_users do |t|
    	t.column :id_app, :string; #Add app name
    	t.column :id_user, :string; #Add app domain url (http://...)
    	t.column :is_admin, :boolean; #true si id_user is an app admin, else false
    end
  end

  def down
    destroy_table :appUsers;
  end
end
