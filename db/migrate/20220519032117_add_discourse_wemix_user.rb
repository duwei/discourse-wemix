class AddDiscourseWemixUser < ActiveRecord::Migration[6.1]
  def up
    add_column :users, :wemix_id, :string
    add_column :users, :wemix_address, :string
  end

  def down
    remove_column :users, :wemix_id
    remove_column :users, :wemix_address
  end
end
