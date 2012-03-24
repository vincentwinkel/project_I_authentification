class CreateTableAppusers < ActiveRecord::Migration
  def up
    create_table :app_users do |t|
      t.column :application_id, :integer; #Add app ID
      t.column :user_id, :integer; #Add user ID
      #t.column :is_admin, :boolean; #true si id_user is an app admin, else false
    end
  end

  def down
    destroy_table :appUsers;
  end
end
