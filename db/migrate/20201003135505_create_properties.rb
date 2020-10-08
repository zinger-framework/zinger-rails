class CreateProperties < ActiveRecord::Migration[6.0]
  def change
    create_table :properties do |t|
      t.string :name
      t.string :text
      t.string :allowed, array: true
      t.string :default
      t.string :selected, array: true

      t.timestamps

      t.index :name
    end
  end
end
