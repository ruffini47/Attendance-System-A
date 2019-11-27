module UsersHelper
  
  # 勤怠基本情報を指定のフォーマットで返します。
  def format_basic_info(time)
    format("%.2f", ((time.hour * 60) + time.min) / 60.0)
  end
  
  def hour_00(at)
    at.to_s.rjust(2,'0')
  end

  def min_15(at)
    (at.min / 15 * 15).to_s.rjust(2,'0')
  end
  
  def working_times_15(start, finish)
    shour = start.hour
    fhour = finish.hour
    smin_15 = start.min / 15 * 15
    fmin_15 = finish.min / 15 * 15
    
    shour_15 = shour + smin_15 / 60.0
    fhour_15 = fhour + fmin_15 / 60.0

    format("%.2f", fhour_15 - shour_15)
    
  end
  
end
