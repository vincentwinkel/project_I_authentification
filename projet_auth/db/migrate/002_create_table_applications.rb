class CreateTableApplications < ActiveRecord::Migration
  def up
    create_table :applications do |t|
    	t.column :name, :string; #Add app name
    	t.column :url, :string; #Add app domain url (http://...)
    end
  end

  def down
    remove_column :applications, :name;
    remove_column :applications, :url;
    destroy_table :applications;
  end
end
