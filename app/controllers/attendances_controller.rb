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
            attendance.result = ",#{user.name}へ勤怠変更申請中"
          elsif attendance.result.include?("へ勤怠変更申請中") || attendance.result.include?("勤怠編集承認済") || attendance.result.include?("勤怠編集否認")
            result_array = attendance.result.split(",")
            j = 0
            result_array.each do |result0|
              if result0.include?("へ勤怠変更申請中") || result0.include?("勤怠編集承認済") || result0.include?("勤怠編集否認")
                result_array[j] = nil
              end
              j += 1
            end
            str = result_array.join(",")
            
            attendance.result = str
        
            if attendance.result.nil?
              attendance.result = ",#{user.name}へ勤怠変更申請中"
            else
              attendance.result.concat(",#{user.name}へ勤怠変更申請中")
            end
          else
            attendance.result.concat(",#{user.name}へ勤怠変更申請中")
          end
    
          attendance.result.gsub!(",,",",")
          if attendance.result[0] == ","
            attendance.result.slice!(0)
          end
      
          attendance.attendance_change_applying = true 
      
          attendance.save
          user.save
          
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
    min = min1.to_i
    
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
  
    to_superior1 = params[:attendance][:to_superior]
    
    
    if to_superior1 == ""
      flash[:danger] = "指示者確認欄が空です。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end
    
    to_superior = to_superior1.to_i
    
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
        @attendance.result = ",#{user.name}へ残業申請中"
      elsif @attendance.result.include?("へ残業申請中") || @attendance.result.include?("残業承認済") || @attendance.result.include?("残業否認")
        result_array = @attendance.result.split(",")
        j = 0
        result_array.each do |result0|
          if result0.include?("へ残業申請中") || result0.include?("残業承認済") || result0.include?("残業否認")
            result_array[j] = nil
          end
          j += 1
        end
        str = result_array.join(",")
        
        @attendance.result = str
        
        if @attendance.result.nil?
          @attendance.result = ",#{user.name}へ残業申請中"
        else
          @attendance.result.concat(",#{user.name}へ残業申請中")
        end
      else
        @attendance.result.concat(",#{user.name}へ残業申請中")
      end
    
      @attendance.result.gsub!(",,",",")
      if @attendance.result[0] == ","
        @attendance.result.slice!(0)
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
    
    users = User.all
    @attendancesb = []
    @user_b = []
    @attendancesb_number_b = []
    i = 0
    users.each do |user|
      if user.attendances.where(overtime_applying: true).where(to_superior_user_id: params[:id].to_i).count > 0
        # @attendances[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザuser[i]の(worked_onで並べ替えた)attendances
        @attendancesb[i] = user.attendances.where(overtime_applying: true).where(to_superior_user_id: params[:id].to_i).order(:worked_on)
        # @user[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザ
        @user_b[i] =  User.find(@attendancesb[i].first.user_id)         
        i += 1
      end
    end
    
    
    @user_number_b = i
    
    j = 0
    @user_number_b.times do
      @attendancesb_number_b[j] = @attendancesb[j].length 
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
    
    # mは申請元ユーザの数
    #m = params[:attendance][:user_id].length
    
    user = []
    id = []
    attendance = []
    first_day = []
    
    #attendance[i]i番目の申請元のattendance
    #id[i]はi番目の申請元のattendance.id
    for i in 0..n-1 do
      attendance[i] = Attendance.find(params[:attendance][:id][i])
      user[i] = User.find(attendance[i].user_id)
      id[i]= attendance[i].id
      first_day[i] = attendance[i].worked_on.beginning_of_month
    end
    
    #user[j]はi番目の申請元ユーザ
    #for j in 0..m-1 do
    #  user[j] = User.find(params[:attendance][:user_id][j])
    #end
    
    # 共通の処理終わり
    ##########################################################
    
    
    
    
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    
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
    
    instructor_confirmation = []
    change_approval = []
    #user[i]はi番目の申請元ユーザ
    #attendance[i]はi番目の申請元のattendance
    for i in 0..n-1 do
      #user[i] = User.find(params[:attendance][:user_id][i])
      #attendance[i] = Attendance.find(params[:attendance][:id][i])
      instructor_confirmation1 = params[:attendance][:instructor_confirmation]
      if instructor_confirmation1 == nil
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id)  and return
      elsif instructor_confirmation1.length != n
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id)  and return
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
          result_array = attendance[i].result.split(",")
          j = 0
          result_array.each do |result0|
            if result0.include?("へ残業申請中")
              result_array[j] = nil
              
            end
            j += 1
          end
          str = result_array.join(",")
          attendance[i].result = str
          attendance[i].result.concat(",")
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
    
    users = User.all
    @attendancesc = []
    @user_c = []
    @attendancesc_number_c = []
    i = 0
    users.each do |user|
      if user.attendances.where(attendance_change_applying: true).where(attendance_change_to_superior_user_id: params[:id].to_i).count > 0
        # @attendances[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザuser[i]の(worked_onで並べ替えた)attendances
        @attendancesc[i] = user.attendances.where(attendance_change_applying: true).where(attendance_change_to_superior_user_id: params[:id].to_i).order(:worked_on)
        # @user[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザ
        @user_c[i] =  User.find(@attendancesc[i].first.user_id)         
        i += 1
      end
    end
    
    
    @user_number_c = i
    
    j = 0
    @user_number_c.times do
      @attendancesc_number_c[j] = @attendancesc[j].length 
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
    
    # ここはenumの定義により敢えてinstructor_confirmations
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
          str = result_array.join(",")
          attendance[i].result = str
          attendance[i].result.concat(",")
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
    
    to_superior1 = params[:manager_approval_to_superior]
    
    if to_superior1 == ""
      flash[:danger] = "指示者確認欄が空です。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end
    
    to_superior = to_superior1.to_i
    
    # userは申請先上長ユーザ
    user = User.find(to_superior)
    
    attendances = @user.attendances.where(worked_on:@first_day)
    attendance = attendances.first
    
    
    ###################################################################
    # 過去に指定したattendanceと同じattendanceに残業申請する場合
    if attendance.manager_approval_applying == true
          
      #前回と違う上長を指定した場合
      if attendance.manager_approval_to_superior_user_id != to_superior
            
        previous_superior_user = User.find(attendance.manager_approval_to_superior_user_id)
        previous_superior_user.number_of_manager_approval_applied -= 1
        previous_superior_user.save
      
          
        user.number_of_manager_approval_applied += 1
        # 申請元attendanceに申請先user.idの値を持たせるカラムmanager_approval_to_superior_user_id        
        attendance.manager_approval_to_superior_user_id = to_superior
      
        
      # 前回と同じ上長を指定している場合
      else
        
        # 何もしない
        
      end
        
    # 過去に指定した@attendanceと同じattendanceに残業申請する場合終わり
    ###################################################################
      
    ###################################################################
    # 過去に指定していないattendanceに登録する場合
    
    else
      user.number_of_manager_approval_applied += 1
      # 申請元attendanceに申請先user.idの値を持たせるカラムattendance_change_to_superior_user_id
      attendance.manager_approval_to_superior_user_id = to_superior
      
    end
      
    # 過去に指定していないattendanceに登録する場合終わり
    ###################################################################
       
   
    
    if attendance.result.nil?
      attendance.result = ",#{user.name}へ所属長承認申請中"
    elsif attendance.result.include?("へ所属長承認申請中") || attendance.result.include?("から承認済") || attendance.result.include?("から否認")
      result_array = attendance.result.split(",")
      j = 0
      result_array.each do |result0|
        if result0.include?("へ所属長承認申請中") || result0.include?("から承認済") || result0.include?("から否認")
          result_array[j] = nil
        end
        j += 1
      end

      str = result_array.join(",")
     
      attendance.result = str
        
      if attendance.result.nil?
        attendance.result = ",#{user.name}へ所属長承認申請中"
      else
        attendance.result.concat(",#{user.name}へ所属長承認申請中")
      end
    else
        attendance.result.concat(",#{user.name}へ所属長承認申請中")
    end
  
    attendance.result.gsub!(",,",",")
    if attendance.result[0] == ","
      attendance.result.slice!(0)
    end  
    
  
    attendance.manager_approval_applying = true   
  
    attendance.save
    user.save
    redirect_to user_url(@user.id, date:@first_day)
    
  end
  
  def edit_manager_approval_approval
    
    users = User.all
    @attendancesd = []
    @user_d = []
    @attendancesd_number_d = []
    i = 0
    users.each do |user|
      if user.attendances.where(manager_approval_applying: true).where(manager_approval_to_superior_user_id: params[:id].to_i).count > 0
        # @attendances[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザuser[i]の(worked_onで並べ替えた)attendances
        @attendancesd[i] = user.attendances.where(manager_approval_applying: true).where(manager_approval_to_superior_user_id: params[:id].to_i).order(:worked_on)
        # @user[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザ
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
  
  def update_manager_approval_approval
    
  ##########################################################
    # 共通の処理
    
    # 申請先上長ユーザが@user
    @user = User.find(params[:id])
    
    # nは申請元の件数
    n = params[:attendance][:id].length
    
    @first_day = params[:date]
    
    # 共通の処理終わり
    ##########################################################  
    
    
    
    
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
