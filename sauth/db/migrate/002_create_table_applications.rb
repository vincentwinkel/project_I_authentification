class CreateTableApplications < ActiveRecord::Migration
  def up
    create_table :applications do |t|
      t.column :name, :string; #Add app name
      t.column :url, :string; #Add app domain url (http://...)
      t.column :admin, :string; #Add app admin
    end
  end

  def down
    destroy_table :applications;
  end
end
