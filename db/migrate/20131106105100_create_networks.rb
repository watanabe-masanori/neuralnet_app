class CreateNetworks < ActiveRecord::Migration
  def change
    create_table :networks do |t|
      t.string :title
      t.integer :input
      t.integer :middle
      t.integer :output
      t.string :weight

      t.timestamps
    end
  end
end
