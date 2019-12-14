module AttendancesHelper
  
  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      return '出勤' if attendance.started_at.nil?
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    false
  end
  
  # 出勤時間と退勤時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish, tomorrow)
    shour = start.hour
    fhour = finish.hour
    smin = start.min
    fmin = finish.min
    
    shour = shour + smin / 60.0
    fhour = fhour + fmin / 60.0

    if tomorrow == 1 || fhour - shour < 0
      format("%.2f", fhour - shour + 24.0)
    else
      format("%.2f", fhour - shour)
    end
  end
  
  def short_times(time)
    hour = time.hour
    min = time.min
    
    format("%02d:%02d", hour, min)
  end
end
