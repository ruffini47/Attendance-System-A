class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month, :edit_overtime_application, :update_overtime_application,
                                        :edit_overtime_approval, :update_overtime_approval]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month, :confirm_one_month_application, :confirm_one_month_approval, :confirm_one_month_attendance_change_approval]
  before_action :set_one_month_2, only: [:update_overtime_approval, :post_manager_approval_application]
  before_action :not_admin_user, only: [:edit_one_month, :update_one_month, :edit_overtime_application, :update_overtime_application,
                                        :edit_overtime_approval, :update_overtime_approval]
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attribute(:started_at, Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attribute(:finished_at, Time.current.change(sec: 0))
        #update_attribute(:remember_digest, User.digest(remember_token))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    @first_day = @attendance.worked_on
    
    redirect_to user_url(@user, date: @first_day.beginning_of_month)
    
  end
  
  def edit_one_month
  end
  
  def update_one_month
    @first_day = params[:date].to_date
    
    # @userは申請元ユーザ
    @user = User.find(params[:id])
    #params[:user][:attendances]["1"]
    
    
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        # attendanceは申請元attendance
        attendance = Attendance.find(id)
        if item["attendance_hour"] != "" || item["attendance_min"] != "" || item["departure_hour"] != "" || item["departure_min"] != "" 
          year = @first_day.year
          mon = @first_day.month
          day = @first_day.day
          
          attendance_hour = item["attendance_hour"].to_i
          attendance_min = item["attendance_min"].to_i
          temp_after_change_start_time = DateTime.new(year, mon, day, attendance_hour, attendance_min, 0, 0.375);
          attendance.temp_after_change_start_time = temp_after_change_start_time

          departure_hour = item["departure_hour"].to_i
          departure_min = item["departure_min"].to_i
          temp_after_change_end_time = DateTime.new(year, mon, day, departure_hour, departure_min, 0, 0.375);
          attendance.temp_after_change_end_time = temp_after_change_end_time

          temp_attendance_change_note = item["attendance_change_note"]
          attendance.temp_attendance_change_note = temp_attendance_change_note
          
          if item["attendance_change_to_superior_user_id"] == ""
            flash[:danger] = "指示者確認欄が空です。"
            redirect_to user_url(@user.id, date: @first_day)  and return
          end  
    
          to_superior= item["attendance_change_to_superior_user_id"].to_i
          
          # userは申請先上長ユーザ
          user = User.find(to_superior)
          
          
          ###################################################################
          # 過去に指定したattendanceと同じattendanceに残業申請する場合
          if attendance.attendance_change_applying == true
          
            #前回と違う上長を指定した場合
            if attendance.attendance_change_to_superior_user_id != to_superior
            
              previous_superior_user = User.find(attendance.attendance_change_to_superior_user_id)
              previous_superior_user.number_of_attendance_change_applied -= 1
              previous_superior_user.save
      
          
              user.number_of_attendance_change_applied += 1
              # 申請元attendanceに申請先user.idの値を持たせるカラムattendance_change_to_superior_user_id        
              attendance.attendance_change_to_superior_user_id = to_superior
      
        
            # 前回と同じ上長を指定している場合
            else
          
              # 何もしない
        
            end
        
          # 過去に指定した@attendanceと同じattendanceに残業申請する場合終わり
          ###################################################################
      
          ###################################################################
          # 過去に指定していないattendanceに登録する場合
    
          else
            user.number_of_attendance_change_applied += 1
            # 申請元attendanceに申請先user.idの値を持たせるカラムattendance_change_to_superior_user_id
            attendance.attendance_change_to_superior_user_id = to_superior
          end
      
          # 過去に指定していないattendanceに登録する場合終わり
          ###################################################################
    
      
          if attendance.result.nil?
            attendance.result = " #{user.name}へ勤怠変更申請中 "
          elsif attendance.result.include?("へ勤怠変更申請中") || attendance.result.include?("勤怠編集承認済") || attendance.result.include?("勤怠編集否認")
            result_array = attendance.result.split
            j = 0
            result_array.each do |result0|
              if result0.include?("へ勤怠変更申請中") || result0.include?("勤怠編集承認済") || result0.include?("勤怠編集否認")
                result_array[j] = nil
              end
              j += 1
            end

            str = result_array.join
            attendance.result = str
        
            if attendance.result.nil?
              attendance.result = " #{user.name}へ勤怠変更申請中 "
            else
              attendance.result.concat(" #{user.name}へ勤怠変更申請中 ")
            end
          else
            attendance.result.concat(" #{user.name}へ勤怠変更申請中 ")
          end
    
      
          attendance.attendance_change_applying = true 
      
      
          user.save
      
          #if attendance.update_attributes(update_overtime_application_params)
          #else
          #  render :show      
          #end
      
          #attendance.save
    
          # 変更を送信するボタン押下後の処理終わり
          ##########################################################
          
        end
        attendance.update_attributes!(item)
      end
    end
    
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
      redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  def at_work
    @users = User.all
    @attendances =  Attendance.all
    @attendances =  @attendances.where(worked_on: Date.today)
    @attendances = @attendances.where.not(started_at: nil)
    @attendances = @attendances.where(finished_at: nil).order(:user_id)
  end
  
  def edit_overtime_application
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @first_day = params[:date]
    
  end
  
  def update_overtime_application
    ##########################################################
    # 共通の処理
    
    @first_day = params[:date].to_date
    
    #require "date"
    # @userは申請元ユーザ
    @user = User.find(params[:user_id])
    # @attendanceは申請元ユーザの@attendance
    @attendance = Attendance.find(params[:id])
    
    hour1 = params[:attendance][:hour]
    min1 =  params[:attendance][:min] 

    if hour1 == "" || min1 == ""
      flash[:danger] = "終了予定時間が空です。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end  

    hour = hour1.to_i
    min = min.to_i
    
    # 共通の処理終わり
    ##########################################################
    
    
    
    
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    if params[:confirmation] == "確認"
      
      business_processing = params[:attendance][:business_processing]
      @attendance.cl_business_processing = business_processing
      
      if @attendance.update_attributes(attendance_confirm_one_month_application_user_params)
        redirect_to attendance_confirm_one_month_application_user_url(@user.id, @attendance.id, hour, min, date: @first_day) and return
      else
        render :show      
      end
      
      
      
      
      #@attendance.save
      
      
      
    
    end
    # 勤怠を確認するボタン押下後の処理終わり
    ##########################################################
  
  
  
    ##########################################################
    # 変更を送信するボタン押下後の処理
    
    year = Time.now.year
    mon = Time.now.mon
    day = Time.now.day
    
    d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
       
    @attendance.temp_scheduled_end_time = d1
    @attendance.tomorrow = params[:attendance][:tomorrow].to_i
    
    change_application = params[:attendance][:change_application].to_i
    
    temp_business_processing = params[:attendance][:business_processing]
    @attendance.temp_business_processing = temp_business_processing
  
    to_superior = params[:attendance][:to_superior]
    
    
    if to_superior == ""
      flash[:danger] = "指示者確認欄が空です。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end
    
    # userは申請先ユーザ
    user = User.find(to_superior)
    
    
    if change_application == 1
      
      ###################################################################
      # 過去に指定した@attendanceと同じ@attendanceに残業申請する場合
      if @attendance.overtime_applying == true
          
        #前回と違う上長を指定した場合
        if @attendance.to_superior_user_id != user.id
            
            previous_superior_user = User.find(@attendance.to_superior_user_id)
            previous_superior_user.number_of_overtime_applied -= 1
            previous_superior_user.save
      
                   
            #if previous_superior_user.update_attributes(previous_superior_params)
            #else
            #  render :show      
            #end
      
      
      
      
        
            user.number_of_overtime_applied += 1
            # 申請元@attendanceに申請先user.idの値を持たせるカラムto_superior_user_id        
            @attendance.to_superior_user_id = user.id
      
        
        # 前回と同じ上長を指定している場合
        else
          
          # 何もしない
        
        end
        
      # 過去に指定した@attendanceと同じattendanceに残業申請する場合終わり
      ###################################################################
      
      ###################################################################
      # 過去に指定していない@attendanceに登録する場合
    
      else
        user.number_of_overtime_applied += 1
        # 申請元@attendanceに申請先user.idの値を持たせるカラムto_superior_user_id
        @attendance.to_superior_user_id = user.id
      end
      
      # 過去に指定していないattendanceに登録する場合終わり
      ###################################################################
    
    
      
      if @attendance.result.nil?
        @attendance.result = " #{user.name}へ残業申請中 "
      elsif @attendance.result.include?("へ残業申請中") || @attendance.result.include?("残業承認済") || @attendance.result.include?("残業否認")
        result_array = @attendance.result.split
        j = 0
        result_array.each do |result0|
          if result0.include?("へ残業申請中") || result0.include?("残業承認済") || result0.include?("残業否認")
            result_array[j] = nil
          end
          j += 1
        end

        str = result_array.join
        @attendance.result = str
        
        if @attendance.result.nil?
          @attendance.result = " #{user.name}へ残業申請中 "
        else
          @attendance.result.concat(" #{user.name}へ残業申請中 ")
        end
      else
        @attendance.result.concat(" #{user.name}へ残業申請中 ")
      end
    
      #@attendance.previous_superior_user_id = user.id
      @attendance.overtime_applying = true 
      
      
      user.save
      
      if @attendance.update_attributes(update_overtime_application_params)
      else
        render :show      
      end
      
      @attendance.save
    
    
    end
    
    
    redirect_to user_url(@user.id, date: @first_day)
  

    # 変更を送信するボタン押下後の処理終わり
    ##########################################################
  
  
  
  end
  
  
  
  def confirm_one_month_application
    
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @worked_sum = @attendances.where.not(finished_at: nil).count
    year = Time.now.year
    mon = Time.now.mon
    day = Time.now.day
    hour = params[:hour].to_i
    min = params[:min].to_i
    d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
    @attendance.cl_scheduled_end_time = d1

    
    @attendance.save
    
    
      
  end
  
  def cancel_confirm_one_month
  
    @first_day = params[:date].to_date
    @user = User.find(params[:id])
    @attendances = Attendance.all
    
    @attendances.each do |attendance|
      attendance.cl_scheduled_end_time = nil
      attendance.cl_business_processing = nil
      attendance.cr_scheduled_end_time = nil
      attendance.cr_business_processing = nil
      attendance.save
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    
  end
  
  
  
  def edit_overtime_approval
    
    @users = User.all
    @attendances = Attendance.all
    @first_day = params[:date]
    
    
    a = []
    @attendancesb = []

    i = 0
    n = 0
    
    user_ids = []
    
    @attendances.each do |attendance|
      # 申請元のattendanceがapplyしていて、かつ、申請元のattendanceのto_superioro_user_idカラムが申請先のユーザidを指すものだけ取り出す
      if attendance.overtime_applying  == true && attendance.to_superior_user_id == params[:id].to_i
        user_ids[0] = attendance.user_id
      end
    end
    
    hit = false
    @attendances.each do |attendance|
      if attendance.overtime_applying == true && attendance.to_superior_user_id == params[:id].to_i
        n += 1
        user_ids.each do |user_id|
          if attendance.user_id == user_id
            hit = true
            #puts "hit"
          end
        end
        if hit == false
          #puts "not hit"
          i += 1
          user_ids[i] = attendance.user_id
        end
        hit = false
        a.push([attendance.user_id,attendance.worked_on])
        @attendancesb.push(attendance)
      end
    end
    
    @user_id_number = user_ids.length
    puts "user_id_number = #{@user_id_number}"
 
    
    # user.designated_work_end_timeの設定 
    i = 0
    user = []
    @attendancesb.each do |attendance|
      user_ids.each do |user_id|
        if user_id == attendance.user_id
          user[i] = User.find(attendance.user_id)
          year = Time.now.year
          mon = Time.now.mon
          day = Time.now.day
          hour = user[i].designated_work_end_time.hour
          min = user[i].designated_work_end_time.min
          d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
          user[i].designated_work_end_time = d1
          user[i].save
          
          i += 1
        end
      end
    end
    

    

    puts "n= #{n}"

    count = []

    for i in 0..n-1
      count.push(0)
    end

    for i in 0..n-1 do
      for j in 0..n-1
        if a[i][0] != a[j][0]
          count[i] += 1
        end
      end
    end

    for i in 0..n-1 do
      count[i] = n - count[i]
    end

    p count

    @count_max = []

    isBreak = false
    i = 0
    if @user_id_number == 1
      @count_max.push(n)
    else
      for m in 0..@user_id_number-1 do
        for j in 1..n-1 do
          #puts "m = #{m} i = #{i} j = #{j}"
          if !a[i + j].nil?
            isBreak = false 
            if a[i][0] != a[i + j][0]
              @count_max.push(j)
              i += j
              isBreak = true
              break
            end
          elsif !(a[i + j - 1].nil?) && a[i + j].nil?
            @count_max.push(j)
          end
          break if isBreak
        end
      end
    end

    puts "@count_max ="
    p @count_max

    puts "count_maxが答えだ！！"

    @count_max_sum = []
    @count_max_sum[0] = 0
    #count_max_sum[1] = count_max[0]
    #count_max_sum[2] = count_max[0] + count_max[1]
    #count_max_sum[3] = count_max[0] + count_max[1] +count_max[2]
    for k in 1..@user_id_number-1 do
      @count_max_sum[k] = @count_max_sum[k-1] + @count_max[k-1]
    end

    # ここまではtemp_business_processing 行っている。
    #@attendancesb.first.temp_business_processing

    
    #users[j]はj番目の申請元ユーザ
    j = 0
    users = []
    for n in 0..(@user_id_number-1) do 
      i = @count_max_sum[n]
      users[j] = User.find(@attendancesb[i].user_id)
      j += 1
    end 
    
    
    

  end

  def update_overtime_approval
    ##########################################################
    # 共通の処理
    
    # 申請先上長ユーザが@user
    @user = User.find(params[:id])
    
    # nは申請元の件数
    n = params[:attendance][:id].length
    
    @first_day = params[:date]
    
    # 共通の処理終わり
    ##########################################################
    
    
    
    
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    
    
    user = []
    id = []
    attendance = []
    first_day = []
    #user[i]はi番目の申請元ユーザ
    #attendance[i]i番目の申請元のattendance
    #id[i]はi番目の申請元のattendance.id
    for i in 0..n-1 do
      user[i] = User.find(params[:attendance][:user_id][i])
      attendance[i] = Attendance.find(params[:attendance][:id][i])
      id[i]= attendance[i].id
      first_day[i] = attendance[i].worked_on.beginning_of_month
    end
    
    
    for i in 0..n-1 do
      if params[:"#{id[i]}"] == "確認"
        
        cr_business_processing = attendance[i].temp_business_processing
        attendance[i].cr_business_processing = cr_business_processing
        attendance[i].save
        
        j = i
          
        redirect_to attendance_confirm_one_month_approval_user_url(user[j].id, id[j], date: first_day[j]) and return  
      
      end
    end
    
    
    # 勤怠を確認するボタン押下後の処理終わり
    ##########################################################
    
    
    
    ##########################################################
    # 変更を送信するボタン押下後の処理
    
    
    attendance = []
    instructor_confirmation = []
    change_approval = []
    #user[i]はi番目の申請元ユーザ
    #attendance[i]はi番目の申請元のattendance
    for i in 0..n-1 do
      user[i] = User.find(params[:attendance][:user_id][i])
      attendance[i] = Attendance.find(params[:attendance][:id][i])
      
      
      instructor_confirmation1 = params[:attendance][:instructor_confirmation]
      if instructor_confirmation1 == nil
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id, date: @first_day)  and return
      end
      instructor_confirmation[i] = params[:attendance][:instructor_confirmation][i].to_i
    end

    change_approval = params[:attendance][:change_approval]
    
    i = 0
    change_approval.length.times do
      if change_approval[i] == "true"
        change_approval.delete_at(i-1)
        i -= 1
      end
      i += 1
    end
    
    inst_hash = Attendance.instructor_confirmations
    result = []
    #result[i]はi番目の"なし","申請中","承認","否認"などの結果文字列
    for i in 0..n-1 do
      result[i] = inst_hash.invert[instructor_confirmation[i]]
    end
    for i in 0..n-1 do
      if instructor_confirmation[i] == 2
        result[i] = " 残業承認済 "
      elsif instructor_confirmation[i] == 3
        result[i] = " 残業否認 "
      else
        result[i] = ""
      end
    end
      
    for i in 0..n-1 do
          
      if instructor_confirmation[i] == 2 && change_approval[i] == "true" 
        
        attendance[i].business_processing = attendance[i].temp_business_processing
        attendance[i].temp_business_processing = nil
        attendance[i].scheduled_end_time = attendance[i].temp_scheduled_end_time
        attendance[i].temp_scheduled_end_time = nil
        
      end
      
      if (instructor_confirmation[i] == 2 || instructor_confirmation[i] == 3 ) && change_approval[i] == "true"                
        
        @user.number_of_overtime_applied -= 1
        attendance[i].overtime_applying = false
        
        if attendance[i].result.nil?
          attendance[i].result = result[i]  
        elsif attendance[i].result.include?("へ残業申請中")
          # @attendance.resultの残業申請中の文字列を消す
          result_array = attendance[i].result.split
          j = 0
          result_array.each do |result0|
            if result0.include?("へ残業申請中")
              result_array[j] = nil
            end
            j += 1
          end
          str = result_array.join
          attendance[i].result = str
          attendance[i].result.concat(result[i])
        end
      
        if attendance[i].update_attributes(update_overtime_approval_params)
        else
          render :show      
        end
      
        @user.save
      
      end
      
      
      
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    # 変更を送信するボタン押下後の処理終わり
    ##########################################################
    
  end
  
  def confirm_one_month_approval
    
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @worked_sum = @attendances.where.not(finished_at: nil).count
    
    @attendance.cr_scheduled_end_time = @attendance.temp_scheduled_end_time
    @attendance.save
    
  end
  
  
  
  
  def edit_attendance_change_approval
    
    @users = User.all
    @attendances = Attendance.all
    @first_day = params[:date]
    
    
    
    c = []
    @attendancesc = []

    i = 0
    n = 0
    user_ids_c = []
    @attendances.each do |attendance|
      # 申請元のattendanceがattendance_change_applyしていて、かつ、申請元のattendanceのattendance_change_to_superior_user_idカラムが申請先のユーザidを指すものだけ取り出す
      if attendance.attendance_change_applying  == true && attendance.attendance_change_to_superior_user_id == params[:id].to_i
        user_ids_c[0] = attendance.user_id
      end
    end
    
    hit = false
    @attendances.each do |attendance|
      if attendance.attendance_change_applying == true && attendance.attendance_change_to_superior_user_id == params[:id].to_i
        n += 1
        user_ids_c.each do |user_id|
          if attendance.user_id == user_id
            hit = true
            #puts "hit"
          end
        end
        if hit == false
          #puts "not hit"
          i += 1
          user_ids_c[i] = attendance.user_id
        end
        hit = false
        c.push([attendance.user_id,attendance.worked_on])
        @attendancesc.push(attendance)
        
      end
    end
    
    @user_id_number_c= user_ids_c.length
    puts "user_id_number_c = #{@user_id_number_c}"
 
 
    # user.designated_work_end_timeの設定 
    i = 0
    user = []
    @attendancesc.each do |attendance|
      user_ids_c.each do |user_id|
        if user_id == attendance.user_id
          user[i] = User.find(attendance.user_id)
          year = Time.now.year
          mon = Time.now.mon
          day = Time.now.day
          
          #@after_change_start_hour = user[i].after_change_start_time.hour
          #@after_change_strat_min = user[i].after_change_start_time.min
          #d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
          #user[i].designated_work_end_time = d1
          #user[i].save
          
          i += 1
        end
      end
    end
    

    

    puts "n= #{n}"

    count_c = []

    for i in 0..n-1
      count_c.push(0)
    end

    for i in 0..n-1 do
      for j in 0..n-1
        if c[i][0] != c[j][0]
          count_c[i] += 1
        end
      end
    end

    for i in 0..n-1 do
      count_c[i] = n - count_c[i]
    end

    p count_c

    @count_max_c = []

    isBreak = false
    i = 0
    if @user_id_number_c == 1
      @count_max_c.push(n)
    else
      for m in 0..@user_id_number_c-1 do
        for j in 1..n-1 do
          #puts "m = #{m} i = #{i} j = #{j}"
          if !c[i + j].nil?
            isBreak = false 
            if c[i][0] != c[i + j][0]
              @count_max_c.push(j)
              i += j
              isBreak = true
              break
            end
          elsif !(c[i + j - 1].nil?) && c[i + j].nil?
            @count_max_c.push(j)
          end
          break if isBreak
        end
      end
    end

    puts "@count_max_c ="
    p @count_max_c

    puts "count_max_cが答えだ！！"

    @count_max_sum_c= []
    @count_max_sum_c[0] = 0
    #count_max_sum_c[1] = count_max_c[0]
    #count_max_sum_c[2] = count_max_c[0] + count_max_c[1]
    #count_max_sum_c[3] = count_max_c[0] + count_max_c[1] +count_max_c[2]
    for k in 1..@user_id_number_c-1 do
      @count_max_sum_c[k] = @count_max_sum_c[k-1] + @count_max_c[k-1]
    end

    # ここまではtemp_business_processing 行っている。
    #@attendancesb.first.temp_business_processing

    
    #users_c[j]はj番目の申請元ユーザ
    j = 0
    users_c = []
    for n in 0..(@user_id_number_c-1) do 
      i = @count_max_sum_c[n]
      users_c[j] = User.find(@attendancesc[i].user_id)
      j += 1
    end 
    
  end


  def update_attendance_change_approval

    ##########################################################
    # 共通の処理
    
    # 申請先上長ユーザが@user
    @user = User.find(params[:id])
    
    # nは申請元の件数
    n = params[:attendance][:id].length
    
    @first_day = params[:date]
    
    # 共通の処理終わり
    ##########################################################
    
  
  
  ##########################################################
    # 勤怠を確認ボタン押下後の処理
    
    
    user = []
    id = []
    attendance = []
    first_day = []
    #user[i]はi番目の申請元ユーザ
    #attendance[i]i番目の申請元のattendance
    #id[i]はi番目の申請元のattendance.id
    for i in 0..n-1 do
      user[i] = User.find(params[:attendance][:user_id][i])
      attendance[i] = Attendance.find(params[:attendance][:id][i])
      id[i]= attendance[i].id
      first_day[i] = attendance[i].worked_on.beginning_of_month
    end
    
    
    for i in 0..n-1 do
      if params[:"#{id[i]}"] == "確認"
        
        j = i
        
        redirect_to attendance_confirm_one_month_attendance_change_approval_user_path(user[j].id, id[j], date: first_day[j]) and return  
      
      end
    end
    
    
    # 勤怠を確認するボタン押下後の処理終わり
    ##########################################################
    
  
  
    ##########################################################
    # 変更を送信するボタン押下後の処理
    
    
    attendance = []
    attendance_change_instructor_confirmation = []
    attendance_change_change_approval = []
    #user[i]はi番目の申請元ユーザ
    #attendance[i]はi番目の申請元のattendance
    for i in 0..n-1 do
      user[i] = User.find(params[:attendance][:user_id][i])
      attendance[i] = Attendance.find(params[:attendance][:id][i])
      attendance_change_instructor_confirmation1 =  params[:attendance][:attendance_change_instructor_confirmation]
      if attendance_change_instructor_confirmation1 == nil
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id, date: @first_day)  and return
      end
      attendance_change_instructor_confirmation[i] = params[:attendance][:attendance_change_instructor_confirmation][i].to_i
    end

    attendance_change_change_approval = params[:attendance][:attendance_change_change_approval]
    
    i = 0
    attendance_change_change_approval.length.times do
      if attendance_change_change_approval[i] == "true"
        attendance_change_change_approval.delete_at(i-1)
        i -= 1
      end
      i += 1
    end
    
    # ここはenumの貞義により敢えてinstructor_confirmations
    inst_hash = Attendance.instructor_confirmations
    result = []
    #result[i]はi番目の"なし","申請中","承認","否認"などの結果文字列
    for i in 0..n-1 do
      result[i] = inst_hash.invert[attendance_change_instructor_confirmation[i]]
    end
    for i in 0..n-1 do
      if attendance_change_instructor_confirmation[i] == 2
        result[i] = " 勤怠編集承認済 "
      elsif attendance_change_instructor_confirmation[i] == 3
        result[i] = " 勤怠編集否認 "
      else
        result[i] = ""
      end
    end
     
    for i in 0..n-1 do
      if attendance_change_instructor_confirmation[i] == 2 && attendance_change_change_approval[i] == "true" 
        
        attendance[i].last_attendance_change_note = attendance[i].temp_attendance_change_note
        attendance[i].temp_attendance_change_note = nil
        
        attendance[i].started_at = attendance[i].temp_after_change_start_time
        attendance[i].temp_after_change_start_time = nil
        
        attendance[i].finished_at = attendance[i].temp_after_change_end_time
        attendance[i].temp_after_change_end_time = nil
        
      end
      
      if ( attendance_change_instructor_confirmation[i] == 2 || attendance_change_instructor_confirmation[i] == 3 ) && attendance_change_change_approval[i] == "true" 
        
        @user.number_of_attendance_change_applied -= 1
        attendance[i].attendance_change_applying = false
        
        if attendance[i].result.nil?
          attendance[i].result = result[i]  
        elsif attendance[i].result.include?("#{@user.name}へ勤怠変更申請中")
          result_array = attendance[i].result.split
          j = 0
          result_array.each do |result0|
            if result0 == "#{@user.name}へ勤怠変更申請中"
              result_array[j] = nil
            end
            j += 1
          end
          str = result_array.join
          attendance[i].result = str
          attendance[i].result.concat(result[i])
        end
      
        @user.save
        
        
        if attendance[i].update_attributes(update_attendance_change_approval_params)
        else
          render :show      
        end
         
        #attendance[i].save!
        
        #attendance[i].save
        #attendance[i].errors

      end
      
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    # 変更を送信するボタン押下後の処理終わり
    ##########################################################
  
  
  end
  
  
  def confirm_one_month_attendance_change_approval
    
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @worked_sum = @attendances.where.not(finished_at: nil).count
    
    @attendance.cr_after_change_start_time = @attendance.temp_after_change_start_time
    @attendance.cr_after_change_end_time = @attendance.temp_after_change_end_time
    @attendance.cr_attendance_change_note = @attendance.temp_attendance_change_note
    @attendance.save
    
    
  end
  
  
  def cancel_attendance_change_confirm_one_month
  
    @first_day = params[:date].to_date
    @user = User.find(params[:id])
    @attendances = Attendance.all
    
    @attendances.each do |attendance|
      attendance.cr_after_change_start_time = nil
      attendance.cr_after_change_end_time = nil
      attendance.cr_attendance_change_note = nil
      attendance.save
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    
  end
  
  def post_manager_approval_application
    # @userは申請元ユーザ
    @user = User.find(params[:id])
    @first_day = params[:date].to_date
    to_superior = params[:manager_approval_to_superior].to_i
    #userは申請先上長ユーザ
    user = User.find(to_superior)
    user.number_of_manager_approval_applied += 1
    user.save
    
    attendances = @user.attendances.where(worked_on:@first_day)
    attendance = attendances.first
    attendance.manager_approval_applying = true
    attendance.manager_approval_to_superior_user_id = to_superior
    attendance.save
    
  end
  
  def edit_manager_approval_approval
    
    users = User.all
    @attendancesd = []
    @user_d = []
    @attendancesd_number_d = []
    i = 0
    users.each do |user|
      if user.attendances.where(manager_approval_applying:true).count > 0
        # @attendances[i]は所属長承認申請しているi番目のユーザuser[i]の(worked_onで並べ替えた)attendances
        @attendancesd[i] = user.attendances.where(manager_approval_applying:true).order(:worked_on)
        # @user[i]は所属長承認申請しているi番目のユーザ
        @user_d[i] =  User.find(@attendancesd[i].first.user_id)         
        i += 1
      end
    end
    
    
    @user_number_d = i
    
    j = 0
    @user_number_d.times do
      @attendancesd_number_d[j] = @attendancesd[j].length 
      j += 1
    end
    
  end
  
  
  private
  
    # 勤怠編集情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:attendance_hour, :attendance_min, :departure_hour, :departure_min,
                                                 :attendance_change_tomorrow, :attendance_change_note, :attendance_change_to_superior_user_id])[:attendances]
    end
    
    # 勤怠変更承認の勤怠情報を扱います。
    def update_attendance_change_approval_params
      params.require(:attendance).permit(attendance: [:attendance_change_instructor_confirmation, :attendance_change_change_approval])
    end
    
    # １ヶ月の残業申請確認を扱います。
    def attendance_confirm_one_month_application_user_params
      params.require(:attendance).permit(:id, :confirmation, attendance: [:business_processing, :hour, :min])
    end
    
    # 残業申請の勤怠情報を扱います。
    def update_overtime_application_params
      params.require(:attendance).permit(:id, :confirmation, attendance: [:hour, :min, :tomorrow, :change_application, :business_processing, :to_superior])
    end
    
    # 残業承認の勤怠情報を扱います。
    def update_overtime_approval_params
      params.require(:attendance).permit(attendance: [:instructor_confirmation, :change_approval])
    end
    
    # beforeフィルター
    
    # 管理者権限、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end
