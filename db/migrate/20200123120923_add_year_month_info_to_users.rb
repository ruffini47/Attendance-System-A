class AddYearMonthInfoToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :temp_year, :integer
    add_column :users, :temp_month, :integer
  end
end
