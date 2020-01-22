class AddTimeLogYearMonthInfoToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :time_log_year, :integer
    add_column :users, :time_log_month, :integer
  end
end
