class CreateTableUsers < ActiveRecord::Migration
	def up
		create_table :users do |t|
			t.column :login, :string; #Add user login
			t.column :password, :string; #Add user password
		end
	end

	def down
	remove_column :users, :login;
	remove_column :users, :password;
	destroy_table :users;
	end
end
