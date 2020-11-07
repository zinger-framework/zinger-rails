class CreateEmployees < ActiveRecord::Migration[6.0]
  def change
    create_table :employees do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.string :otp_secret_key
      t.column :status, 'SMALLINT', default: 1
      t.boolean :deleted, default: false
      t.timestamps

      t.index :email
    end
  end
end

