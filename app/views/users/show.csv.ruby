require "date"
require 'csv'


csv_data= CSV.generate do |csv|
  csv_column_names = %w(Worked_on Started_at Finished_at)
  #csv << csv_column_names
  @attendances.each do |day|
    csv_column_values = [
      day.worked_on,
      day.started_at,
      day.finished_at
    ]
    csv << csv_column_values
  end
end


csv_data2 = CSV.generate do |csv|
  csv_column_names = %w(Worked_on Started_at Finished_at)
  csv << csv_column_names  
  csv_data3 = CSV.parse(csv_data) do |row|
    if !row[1].nil? && !row[2].nil?
      csv << [row[0],row[1].to_datetime.strftime("%H:%M"),row[2].to_datetime.strftime("%H:%M")]
    else
      csv << [row[0],row[1],row[2]]
    end
  end
end
