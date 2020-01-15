require "date"
require 'csv'


csv_data= CSV.generate do |csv|
  csv_column_names = %w(Worked_on Started_at Finished_at)
  #csv << csv_column_names
  @attendances.each do |day|
    if !day.started_at.nil? && !day.finished_at.nil?
      csv_column_values = [
        day.worked_on,
        day.started_at.strftime("%H:%M"),
        day.finished_at.strftime("%H:%M")
      ]
    elsif !day.started_at.nil?
      csv_column_values = [
        day.worked_on,
        day.started_at.strftime("%H:%M"),
        day.finished_at
      ]
    else
      csv_column_values = [
        day.worked_on,
        day.started_at,
        day.finished_at
      ]
    end
    csv << csv_column_values
  end
end


#csv_data2 = CSV.generate do |csv|
#  csv_column_names = %w(Worked_on Started_at Finished_at)
#  csv << csv_column_names  
#  csv_data3 = CSV.parse(csv_data) do |row|
#    if !row[1].nil? && !row[2].nil?
#      csv << [row[0],row[1].to_datetime.strftime("%H:%M"),row[2].to_datetime.strftime("%H:%M")]
#    else
#      csv << [row[0],row[1],row[2]]
#    end
#  end
#end
