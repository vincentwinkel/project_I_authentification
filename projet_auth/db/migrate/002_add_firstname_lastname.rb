class AddFirstnameLastname < ActiveRecord::Migration
  def up
    add_column :people, :login, :string;
    add_column :people, :password, :string;
  end

  def down
    remove_column :people, :login;
    remove_column :people, :password;
  end
end
