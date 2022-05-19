class CreateDiscourseWemixActivity < ActiveRecord::Migration[6.1]
  def up
    create_table :discourse_wemix_activities do |t|
      t.integer :user_id
      t.string :wemix_id
      t.string :wemix_address
      t.integer :activity_type
      t.integer :amount
      t.datetime :pay_at

      t.timestamps
    end
  end

  def down
    drop_table :discourse_wemix_activities
  end
end
