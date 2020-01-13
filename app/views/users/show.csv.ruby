require 'csv'

CSV.generate do |csv|
  csv_column_names = %w(Worked_on Started_at Finished_at)
  csv << csv_column_names
  @attendances.each do |day|
    csv_column_values = [
      day.worked_on,
      day.started_at,
      day.finished_at
    ]
    csv << csv_column_values
  end
end