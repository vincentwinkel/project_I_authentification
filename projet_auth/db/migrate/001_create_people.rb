class CreatePeople < ActiveRecord::Migration
  def up
    create_table :people do |t|
    end
  end

  def down
    destroy_table :people
  end
end
