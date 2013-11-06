class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers do |t|
      t.string :data
      t.references :network, index: true

      t.timestamps
    end
  end
end
