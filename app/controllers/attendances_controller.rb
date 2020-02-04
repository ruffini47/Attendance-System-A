class AttendancesController < ApplicationController
  protect_from_forgery
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month, :update_one_month, :edit_overtime_application, :update_overtime_application,
                                        :edit_overtime_approval, :update_overtime_approval, :edit_attendance_change_approval, :update_attendance_change_approval,
                                        :post_manager_approval_application, :edit_manager_approval_approval, :update_manager_approval_approval]
  #before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month, :confirm_one_month_application, :confirm_one_month_approval,
                                       :confirm_one_month_attendance_change_approval, :confirm_one_month_manager_approval_approval]
  before_action :set_one_month_2, only: [:update_overtime_approval, :post_manager_approval_application]
  before_action :not_admin_user, only: [:update, :edit_one_month, :update_one_month, :edit_overtime_application, :update_overtime_application,
                                        :edit_overtime_approval, :update_overtime_approval, :edit_attendance_change_approval, :update_attendance_change_approval,
                                        :post_manager_approval_application, :edit_manager_approval_approval, :update_manager_approval_approval]
  before_action :admin_user, only: [:at_work]
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
    last_day = @first_day.end_of_month
    @last_attendance =  Attendance.find_by(user_id:@user.id, worked_on:last_day)
    @last_attendance.manager_approval = "所属長承認　未"
    @last_attendance.save
    
    redirect_to user_url(@user, date: @first_day.beginning_of_month)
    
  end
  
  def edit_one_month
  end
  
  def update_one_month
    @first_day = params[:date].to_date
    last_day = @first_day.end_of_month
    
    # @userは申請元ユーザ
    @user = User.find(params[:id])
    # @last_attendance[i]はユーザがi番目の申請元ユーザ、worked_onが月末日のattencance
    @last_attendance =  Attendance.find_by(user_id:@user.id, worked_on:last_day)
    
    delete_id_numbers = []
    
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
          
          attendance_change_tomorrow = item["attendance_change_tomorrow"].to_i
          if attendance_change_tomorrow == 1
            temp_after_change_end_time = temp_after_change_end_time.since(1.days)
          end
          attendance.temp_after_change_end_time = temp_after_change_end_time
          attendance.attendance_change_tomorrow = attendance_change_tomorrow
          
          if temp_after_change_start_time > temp_after_change_end_time
            #実際は下記は表示されない
            flash[:danger] = "翌日チェックボックスをつけてください。"
          end

          temp_attendance_change_note = item["attendance_change_note"]
          attendance.temp_attendance_change_note = temp_attendance_change_note
          
          
          
          if item["attendance_change_to_superior_user_id"] == ""
            # 指示者確認欄が空のときActiveRecordのエラーを発生させる
            item["departure_hour"] = nil
            to_superior = 2
            # 指示者確認欄が空のときActiveRecordのエラーを発生させる終わり
            #実際は下記は表示されない
            flash[:danger] = "指示者確認欄が空です。"
          else
            to_superior= item["attendance_change_to_superior_user_id"].to_i
          end  
          
          # userは申請先上長ユーザ
          user = User.find(to_superior)
          
          
          ###################################################################
          # 過去に指定したattendanceと同じattendanceに勤怠変更申請する場合
          if attendance.attendance_change_applying == true
          
            #前回と違う上長を指定した場合
            if attendance.saved_attendance_change_to_superior_user_id != to_superior
            
              previous_superior_user = User.find(attendance.saved_attendance_change_to_superior_user_id)
              previous_superior_user.number_of_attendance_change_applied -= 1
              previous_superior_user.save
      
          
              user.number_of_attendance_change_applied += 1
              # 申請元attendanceに申請先user.idの値を持たせるカラムattendance_change_to_superior_user_id        
              attendance.attendance_change_to_superior_user_id = to_superior
      
        
            # 前回と同じ上長を指定している場合
            else
          
              attendance.attendance_change_to_superior_user_id = to_superior
        
            end
        
          # 過去に指定した@attendanceと同じattendanceに勤怠変更申請する場合終わり
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
          if attendance.result.end_with?(",")
            attendance.result.chop!
          end
      
          attendance.attendance_change_applying = true 
      
          attendance.saved_attendance_change_to_superior_user_id = attendance.attendance_change_to_superior_user_id
          
          
          @last_attendance.manager_approval = "所属長承認　未"
          @last_attendance.save
      
          
          
          #attendance.save
          user.save
          
          
        end
        #user.save
        unless params[:user][:attendances][id][:attendance_change_to_superior_user_id] == ""
          #params[:user][:attendances][id][:attendance_change_note] == "" &&
          #params[:user][:attendances][id][:attendance_hour] == "" &&
          #params[:user][:attendances][id][:attendance_min] == "" &&
          #params[:user][:attendances][id][:departure_hour] == "" &&
          #params[:user][:attendances][id][:departure_min] == ""
            
            
            delete_id_numbers.push(id)
            
        end
           
        attendance.update_attributes!(item)
        
      end
      
      
      
    end
    
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    
    delete_id_numbers.each do |number|
      attendance1 = Attendance.find(number)
      attendance1.attendance_change_to_superior_user_id = nil
      attendance1.attendance_change_note = nil
      attendance1.attendance_change_tomorrow = nil
      attendance1.saved_attendance_change_note = attendance1.temp_attendance_change_note
      attendance1.temp_attendance_change_note = nil
      
      attendance1.saved_after_change_start_time = attendance1.temp_after_change_start_time
      attendance1.temp_after_change_start_time = nil
      
      attendance1.saved_after_change_end_time = attendance1.temp_after_change_end_time
      attendance1.temp_after_change_end_time = nil
      
      attendance1.save
    end
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
    last_day = @first_day.end_of_month
    
    
    #require "date"
    # @userは申請元ユーザ
    @user = User.find(params[:user_id])
    # @attendanceは申請元ユーザの@attendance
    @attendance = Attendance.find(params[:id])
    # @last_attendance[i]はユーザがi番目の申請元ユーザ、worked_onが月末日のattencance
    @last_attendance =  Attendance.find_by(user_id:@user.id, worked_on:last_day)
    
    year = Time.now.year
    mon = Time.now.mon
    day = Time.now.day
    hour1 = params[:attendance][:hour]
    min1 =  params[:attendance][:min] 

    if hour1 == "" || min1 == ""
      flash[:danger] = "終了予定時間が空です。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end  

    hour = hour1.to_i
    min = min1.to_i
    
    d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
    
    hour2 = @user.designated_work_end_time.hour
    min2 = @user.designated_work_end_time.min
    
    @user.designated_work_end_time = d1.change(hour: hour2, min: min2, sec: 0)
    @user.save
    
    tomorrow = params[:attendance][:tomorrow].to_i
    
    if d1 < @user.designated_work_end_time && tomorrow != 1
      flash[:danger] = "翌日チェックボックスをつけてください。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end
    
    if d1 >= @user.designated_work_end_time && tomorrow == 1
      flash[:danger] = "翌日チェックボックスをつけてないでください。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end
    
    if tomorrow == 1
      d1 = d1.since(1.days)
    end
    
    @attendance.temp_scheduled_end_time = d1
    @attendance.tomorrow = tomorrow


    
    
    # 共通の処理終わり
    ##########################################################
    
    
    
    
    
  
  
    
    
    
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    if params[:confirmation] == "確認"
      
      business_processing = params[:attendance][:business_processing]
      @attendance.cl_business_processing = business_processing
      
      if @attendance.update_attributes(attendance_confirm_one_month_application_user_params)
        redirect_to attendance_confirm_one_month_application_user_url(@user.id, @attendance.id, date: @first_day) and return
      else
        render :show      
      end
      
    
    end
    # 勤怠を確認するボタン押下後の処理終わり
    ##########################################################
  
    ##########################################################
    # 変更を送信するボタン押下後の処理
    
    
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
  
      @attendance.save
      
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
      if @attendance.result.end_with?(",")
        @attendance.result.chop!
      end
    
    
    
    
    
    
    
    
    
    
    
    
      #@attendance.previous_superior_user_id = user.id
      @attendance.overtime_applying = true 
      
      
      user.save
      
      if @attendance.update_attributes(update_overtime_application_params)
      else
        render :show      
      end
    
      @last_attendance.manager_approval = "所属長承認　未"  
      @last_attendance.save
      
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
    
    d1 = @attendance.temp_scheduled_end_time
    
    #year = Time.now.year
    #mon = Time.now.mon
    #day = Time.now.day
    #hour = params[:hour].to_i
    #min = params[:min].to_i
    #d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
    @attendance.cl_scheduled_end_time = d1
    

    
    @attendance.save
    
    
      
  end
  
  def cancel_confirm_one_month_application
  
    @first_day = params[:date].to_date
    # @userは申請元ユーザ
    @user = User.find(params[:user_id])
    @attendances = Attendance.all
    
    # @attendanceは上長ユーザのattendance
    #@attendance = Attendance.find(params[:id])
    
    # userは上長ユーザ
    #user = User.find(@attendance.to_superior_user_id)
    
    @attendances.each do |attendance|
      attendance.cl_scheduled_end_time = nil
      attendance.cl_business_processing = nil
      #attendance.cr_scheduled_end_time = nil
      #attendance.cr_business_processing = nil
      attendance.save
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    
  end
  
  def cancel_confirm_one_month_approval
  
    @first_day = params[:date].to_date
    # @userは申請元ユーザ
    @user = User.find(params[:user_id])
    @attendances = Attendance.all
    
    # @attendanceは上長ユーザのattendance
    @attendance = Attendance.find(params[:id])
    
    # userは上長ユーザ
    user = User.find(attendance.)
    
    @attendances.each do |attendance|
      #attendance.cl_scheduled_end_time = nil
      #attendance.cl_business_processing = nil
      attendance.cr_scheduled_end_time = nil
      attendance.cr_business_processing = nil
      attendance.save
    end
    
    redirect_to user_url(user.id, date: @first_day)
    
  end
  
  def edit_overtime_approval
    
    @users = User.all
    @attendancesb = []
    @user_b = []
    @attendancesb_number_b = []
    i = 0
    @users.each do |user|
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
    
    @users_b = []
    @user_b.each do |user|
      @users_b.push(user)
    end
    
    
  end



  def update_overtime_approval
    ##########################################################
    # 共通の処理
    
    # 申請先上長ユーザが@user
    @user = User.find(params[:id])
    
    # ActionController::Parametersをハッシュ化する
    hash = params[:user][:attendances].permit!.to_hash
    
    # nは申請元の件数
    n = hash.size
    
    # mは申請元ユーザの数
    #m = params[:attendance][:user_id].length
    
    attendance_ids = hash.keys
    
    #attendance[i]i番目の申請元のattendance
    #user[i]はi番目の申請元ユーザuser
    #id[i]はi番目の申請元のattendance.id
    #first_day[i]はi番目の申請元attendanceのfirst_day
    attendance = []
    user = []
    id = []
    first_day = []
    
    i = 0
    
    attendance_ids.each do |idd|
      attendance[i] = Attendance.find(idd.to_i)
      user[i] = User.find(attendance[i].user_id)
      id[i] = idd.to_i
      first_day[i] = attendance[i].worked_on.beginning_of_month
      i += 1
    end
    
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
    
    for i in 0..n-1 do
      instructor_confirmation1 = hash[id[i].to_s]["instructor_confirmation"]
      
      if instructor_confirmation1 == ""
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id, date: first_day[i])  and return
      end
      instructor_confirmation[i] = hash[id[i].to_s]["instructor_confirmation"].to_i
    end
    
    for i in 0..n-1 do
      change_approval[i] = hash[id[i].to_s]["change_approval"]
    end
    
    #inst_hash = Attendance.instructor_confirmations
    result = []
    #result[i]はi番目の"なし","申請中","承認","否認"などの結果文字列

    # for i in 0..n-1 do
    #   result[i] = inst_hash.invert[instructor_confirmation[i]]
    # end
    for i in 0..n-1 do
      if instructor_confirmation[i] == 2
        result[i] = ",残業承認済"
      elsif instructor_confirmation[i] == 3
        result[i] = ",残業否認"
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
          #attendance[i].result.concat(",")
          attendance[i].result.concat(result[i])
        end
      
        
        attendance[i].result.gsub!(",,",",")
        if attendance[i].result[0] == ","
          attendance[i].result.slice!(0)
        end      
        if attendance[i].result.end_with?(",")
          attendance[i].result.chop!
        end
      
        #if attendance[i].update_attributes(update_overtime_approval_params)
        #else
        #  render :show      
        #end
      
        attendance[i].save
        
        @user.save
      
      end
      
      
      
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    # # 変更を送信するボタン押下後の処理終わり
    # ##########################################################
    
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
      if user.attendances.where(attendance_change_applying: true).where(saved_attendance_change_to_superior_user_id: params[:id].to_i).count > 0
        # @attendances[i]は所属長承認申請している申請先上長ユーザが:id番であるi番目のユーザuser[i]の(worked_onで並べ替えた)attendances
        @attendancesc[i] = user.attendances.where(attendance_change_applying: true).where(saved_attendance_change_to_superior_user_id: params[:id].to_i).order(:worked_on)
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
    
    @users_c = []
    @user_c.each do |user|
      @users_c.push(user)
    end
    
    
  end


  def update_attendance_change_approval

    ##########################################################
    # 共通の処理
    
    # 申請先上長ユーザが@user
    @user = User.find(params[:id])
    
    # ActionController::Parametersをハッシュ化する
    hash = params[:user][:attendances].permit!.to_hash
    
    # nは申請元の件数
    n = hash.size

    attendance_ids = hash.keys
    
    #attendance[i]i番目の申請元のattendance
    #user[i]はi番目の申請元ユーザuser
    #id[i]はi番目の申請元のattendance.id
    #first_day[i]はi番目の申請元attendanceのfirst_day
    attendance = []
    user = []
    id = []
    first_day = []
    
    i = 0
    
    attendance_ids.each do |idd|
      attendance[i] = Attendance.find(idd.to_i)
      user[i] = User.find(attendance[i].user_id)
      id[i] = idd.to_i
      first_day[i] = attendance[i].worked_on.beginning_of_month
      i += 1
    end
    
    # 共通の処理終わり
    ##########################################################

    
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    
    
    for i in 0..n-1 do
      if params[:"#{id[i]}"] == "確認"
        
        j = i
        
        redirect_to attendance_confirm_one_month_attendance_change_approval_user_path(user[j].id, id[j], @user.id, date: first_day[j]) and return  
      
      end
    end
    
    
    # 勤怠を確認するボタン押下後の処理終わり
    ##########################################################
    
    ##########################################################
    # 変更を送信するボタン押下後の処理

    attendance_change_instructor_confirmation = []
    attendance_change_change_approval = []
    
    for i in 0..n-1 do
      attendance_change_instructor_confirmation1 = hash[id[i].to_s]["attendance_change_instructor_confirmation"]
      
      if attendance_change_instructor_confirmation1 == ""
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id, date: first_day[i])  and return
      end
      attendance_change_instructor_confirmation[i] = hash[id[i].to_s]["attendance_change_instructor_confirmation"].to_i
    end
    
    for i in 0..n-1 do
      attendance_change_change_approval[i] = hash[id[i].to_s]["attendance_change_change_approval"]
    end
    
    #inst_hash = Attendance.instructor_confirmations
    result = []
    #result[i]はi番目の"なし","申請中","承認","否認"などの結果文字列

    # for i in 0..n-1 do
    #   result[i] = inst_hash.invert[instructor_confirmation[i]]
    # end
    for i in 0..n-1 do
      if attendance_change_instructor_confirmation[i] == 2
        result[i] = ",勤怠編集承認済"
      elsif attendance_change_instructor_confirmation[i] == 3
        result[i] = ",勤怠編集否認"
      else
        result[i] = ""
      end
    end
  
    for i in 0..n-1 do
      if attendance_change_instructor_confirmation[i] == 2 && attendance_change_change_approval[i] == "true" 
        
        attendance[i].last_attendance_change_note = attendance[i].saved_attendance_change_note
        attendance[i].temp_attendance_change_note = nil
        
        attendance[i].started_at = attendance[i].saved_after_change_start_time
        attendance[i].temp_after_change_start_time = nil
        
        attendance[i].finished_at = attendance[i].saved_after_change_end_time
        attendance[i].temp_after_change_end_time = nil
        
        attendance[i].attendance_change_tomorrow = nil

        attendance[i].attendance_change_approved_datetime = DateTime.current

        if attendance[i].time_log_count == 0
          attendance[i].before_change_start_time = attendance[i].started_at
          attendance[i].before_change_end_time = attendance[i].finished_at
        end
        
        attendance[i].time_log_attendance_change_approved = true
        attendance[i].time_log_count += 1
        
      end
      
      if attendance_change_instructor_confirmation[i] == 3 && attendance_change_change_approval[i] == "true" 
        
        attendance[i].temp_attendance_change_note = nil
        
        attendance[i].temp_after_change_start_time = nil
        
        attendance[i].temp_after_change_end_time = nil

        attendance[i].attendance_change_tomorrow = nil        
      end
      
      if ( attendance_change_instructor_confirmation[i] == 2 || attendance_change_instructor_confirmation[i] == 3 ) && attendance_change_change_approval[i] == "true" 
        
        @user.number_of_attendance_change_applied -= 1
        attendance[i].attendance_change_applying = false
        
        if attendance[i].result.nil?
          attendance[i].result = result[i]  
        elsif attendance[i].result.include?("へ勤怠変更申請中")
          result_array = attendance[i].result.split(",")
          j = 0
          result_array.each do |result0|
            if result0.include?("へ勤怠変更申請中")
              result_array[j] = nil
            end
            j += 1
          end
          str = result_array.join(",")
          attendance[i].result = str
          #attendance[i].result.concat(",")
          attendance[i].result.concat(result[i])
        end
      
      
        attendance[i].result.gsub!(",,",",")
        if attendance[i].result[0] == ","
          attendance[i].result.slice!(0)
        end      
        if attendance[i].result.end_with?(",")
          attendance[i].result.chop!
        end
      
        @user.save
        
        attendance[i].save
        
        # if attendance[i].update_attributes(update_attendance_change_approval_params)
        # else
        #   render :show      
        # end
         
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
    
    # @userは申請元ユーザ
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # userは上長ユーザ
    user = User.find(params[:superior_id])
    @attendance.saved_attendance_change_to_superior_user_id = user.id
    @worked_sum = @attendances.where.not(finished_at: nil).count
    
    @attendance.cr_after_change_start_time = @attendance.saved_after_change_start_time
    @attendance.cr_after_change_end_time = @attendance.saved_after_change_end_time
    @attendance.cr_attendance_change_note = @attendance.saved_attendance_change_note
    @attendance.save
    
    
  end
  
  
  def cancel_attendance_change_confirm_one_month
  
    @first_day = params[:date].to_date
    # @userは申請元ユーザ
    @user = User.find(params[:user_id])
    @attendances = Attendance.all
    
    
    @attendance = Attendance.find(params[:id])
    # userは上長ユーザ
    user = User.find(@attendance.saved_attendance_change_to_superior_user_id)



    @attendances.each do |attendance|
      attendance.cr_after_change_start_time = nil
      attendance.cr_after_change_end_time = nil
      attendance.cr_attendance_change_note = nil
      attendance.save
    end
    
    redirect_to user_url(user.id, date: @first_day)
    
  end
  
  def post_manager_approval_application
    # @userは申請元ユーザ
    @user = User.find(params[:id])
    @first_day = params[:date].to_date
    last_day = @first_day.end_of_month
    
    to_superior1 = params[:manager_approval_to_superior]
    
    if to_superior1 == ""
      flash[:danger] = "指示者確認欄が空です。"
      redirect_to user_url(@user.id, date: @first_day)  and return
    end
    
    to_superior = to_superior1.to_i
    
    # userは申請先上長ユーザ
    user = User.find(to_superior)
    
    attendances = @user.attendances.where(worked_on:@first_day)
    # attendances_on_this_monthはユーザが申請元@userで今月中の全てのattendance
    attendances_on_this_month = @user.attendances.where(worked_on:@first_day..last_day)
    # attendanceはユーザが申請元@userで月初のattendance
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
      # 申請元attendanceに申請先user.idの値を持たせるカラムtemp_attendance_change_to_superior_user_id
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
    if attendance.result.end_with?(",")
      attendance.result.chop!
    end
    
    attendances_on_this_month.each do |day|
      if day.overtime_applying == true
        flash[:danger] = "残業申請中は所属長承認はできません。"
        redirect_to user_url(@user.id, date: @first_day)  and return
      end
      
      if day.attendance_change_applying == true
        flash[:danger] = "勤怠変更申請中は所属長承認はできません。"
        redirect_to user_url(@user.id, date: @first_day)  and return
      end  
      
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
    
    @users_d = []
    @user_d.each do |user|
      @users_d.push(user)
    end
    
    
  end
  
  def update_manager_approval_approval
  
  ##########################################################
    # 共通の処理
    
    # 申請先上長ユーザが@user
    @user = User.find(params[:id])
    
    # ActionController::Parametersをハッシュ化する
    hash = params[:user][:attendances].permit!.to_hash
    
    # nは申請元の件数
    n = hash.size
    
    # mは申請元ユーザの数
    #m = params[:attendance][:user_id].length
    
    attendance_ids = hash.keys
    
    #attendance[i]i番目の申請元のattendance
    #user[i]はi番目の申請元ユーザuser
    #id[i]はi番目の申請元のattendance.id
    #first_day[i]はi番目の申請元attendanceのfirst_day
    attendance = []
    user = []
    id = []
    first_day = []
    last_day = []
    
    i = 0
    
    attendance_ids.each do |idd|
      attendance[i] = Attendance.find(idd.to_i)
      user[i] = User.find(attendance[i].user_id)
      id[i] = idd.to_i
      first_day[i] = attendance[i].worked_on.beginning_of_month
      last_day[i] = first_day[i].end_of_month
      i += 1
    end
    
    # 共通の処理終わり
    ##########################################################
    
  
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    
    
    for i in 0..n-1 do
      if params[:"#{id[i]}"] == "確認"
        
        j = i
        
        redirect_to attendance_confirm_one_month_manager_approval_approval_user_path(user[j].id, id[j], date: first_day[j]) and return  
      
      end
    end
    
    
    # 勤怠を確認するボタン押下後の処理終わり
    ##########################################################
  
    ##########################################################
    # 変更を送信するボタン押下後の処理

    manager_approval_instructor_confirmation = []
    manager_approval_change_approval = []
    
    for i in 0..n-1 do
      manager_approval_instructor_confirmation1 = hash[id[i].to_s]["manager_approval_instructor_confirmation"]
      
      if manager_approval_instructor_confirmation1 == ""
        flash[:danger] = "指示者確認欄が空です。"
        redirect_to user_url(@user.id, date: first_day[i])  and return
      end
      manager_approval_instructor_confirmation[i] = hash[id[i].to_s]["manager_approval_instructor_confirmation"].to_i
    end
    
    for i in 0..n-1 do
      manager_approval_change_approval[i] = hash[id[i].to_s]["manager_approval_change_approval"]
    end
    
     
    @last_attendance = []
    
    for i in 0..n-1 do
      
      if ( manager_approval_instructor_confirmation[i] == 2 || manager_approval_instructor_confirmation[i] == 3 ) && manager_approval_change_approval[i] == "true" 
        
        @user.number_of_manager_approval_applied -= 1
        attendance[i].manager_approval_applying = false
        
        #if attendance[i].result.nil?
        #  attendance[i].result = result[i]  
        if attendance[i].result.include?("へ所属長承認申請中")
          result_array = attendance[i].result.split(",")
          j = 0
          result_array.each do |result0|
            if result0.include?("へ所属長承認申請中")
              result_array[j] = nil
            end
            j += 1
          end
          str = result_array.join(",")
          attendance[i].result = str
          #attendance[i].result.concat(",")
          #attendance[i].result.concat(result[i])
        end
      
      
        attendance[i].result.gsub!(",,",",")
        if attendance[i].result[0] == ","
          attendance[i].result.slice!(0)
        end      
        if attendance[i].result.end_with?(",")
          attendance[i].result.chop!
        end
    
      
        @user.save
        
        
        # if attendance[i].update_attributes(update_manager_approval_approval_params)
        # else
        #   render :show      
        # end
         
        attendance[i].save
         
        #attendance[i].save!
        
        #attendance[i].save
        #attendance[i].errors

      end
      
      # @last_attendance[i]はユーザがi番目の申請元ユーザ、worked_onが月末日のattencance
      @last_attendance[i] =  Attendance.find_by(user_id:user[i].id, worked_on:last_day[i])
      
      
      if manager_approval_instructor_confirmation[i] == 2 && manager_approval_change_approval[i] == "true" 
        
        
        
        @last_attendance[i].manager_approval = "所属長承認 #{@user.name}から承認済"
        @last_attendance[i].save
        
        #attendance[i].manager_approval = "所属長承認 #{@user.name}から承認済"
        
        #attendance[i].save
        
        
      end
      
      if manager_approval_instructor_confirmation[i] == 3 && manager_approval_change_approval[i] == "true" 
        
        
        
        @last_attendance[i].manager_approval = "所属長承認 #{@user.name}から否認"
        @last_attendance[i].save
        
        #attendance[i].manager_approval = "所属長承認 否認"
        
        #attendance[i].save
        
      end
      
      
      
    end
    
    redirect_to user_url(@user.id, date: @first_day)
    # 変更を送信するボタン押下後の処理終わり
    ##########################################################
  
  
  
  
    
  end
  
  def confirm_one_month_manager_approval_approval
    
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @worked_sum = @attendances.where.not(finished_at: nil).count
    
    
    #@attendance.cr_manager_approval_start_time = @attendance.started_at
    #@attendance.cr_manager_approval_end_time = @attendance.finished_at
    #@attendance.cr_manager_approval_note = @attendance.last_attendance_change_note
    
    #@attendance.cr_manager_approval_scheduled_end_time = @attendance.scheduled_end_time
    #@attendance.cr_manager_approval_business_processing = @attendance.business_processing
    #@attendance.cr_manager_approval_result = @attendance.result
    
    
    #@attendance.save
    
    
  end
  
  
  def cancel_manager_approval_confirm_one_month
  
    @first_day = params[:date].to_date
    @user = User.find(params[:id])
    @attendances = Attendance.all
    
    
    #@attendances.each do |attendance|
    #  attendance.cr_after_change_start_time = nil
    #  attendance.cr_after_change_end_time = nil
    #  attendance.cr_attendance_change_note = nil
    #  attendance.save
    #end
    
    redirect_to user_url(@user.id, date: @first_day)
    
  end
  
  def time_log
    @user = User.find(params[:id])
    @first_day = params[:date].to_date
    last_day = @first_day.end_of_month
    @attendances = Attendance.all
    @attendances = @user.attendances
    @attendances= @attendances.where(worked_on:@first_day..last_day)
    @attendances = @attendances.where(time_log_attendance_change_approved:true).order(:worked_on)
  end
  
  def update_time_log
    @user = User.find(params[:id])
    if !params[:year].nil?
      year = params[:year].to_i
    elsif !@user.temp_year.nil?
      year = @user.temp_year
    else
      year = Time.now.year
    end
    @user.temp_year = year
    
    if !params[:month].nil?
      month = params[:month].to_i  
    elsif !@user.temp_month.nil?
      month = @user.temp_month
    else
      month = Time.now.mon
    end
    @user.temp_month = month
    
    
    datetime = DateTime.new(year, month, 1, 1, 1, 1, 0.375);
    @first_day = datetime.beginning_of_month
    last_day = @first_day.end_of_month
    @attendances = Attendance.all
    @attendances = @user.attendances
    @attendances= @attendances.where(worked_on:@first_day..last_day)
    @attendances = @attendances.where(time_log_attendance_change_approved:true).order(:worked_on)
    @user.time_log_year = year
    @user.time_log_month = month
    @user.save
    
    redirect_to attendances_time_log_user_path(@user.id, date:@first_day)
    
  end
  
  def reset_time_log
    @user = User.find(params[:id])
    @first_day = params[:date].to_date
    #last_day = @first_day.end_of_month
    #@attendances = Attendance.all
    #@attendances = @user.attendances
    #@attendances= @attendances.where(worked_on:@first_day..last_day)
    #@attendances = @attendances.where(time_log_attendance_change_approved:true).order(:worked_on)
    @user.time_log_year = Time.now.year
    @user.time_log_month = Time.now.mon 
    @user.save
    
    redirect_to attendances_time_log_user_path(@user.id, date:@first_day)
  end
  
  
  private
  
    # 勤怠編集情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:attendance_hour, :attendance_min, :departure_hour, :departure_min,
                                                 :attendance_change_tomorrow, :attendance_change_note, :attendance_change_to_superior_user_id])[:attendances]
    end
    
    # 勤怠変更承認の勤怠情報を扱います。
    # def update_attendance_change_approval_params
    #   params.require(:user).permit(attendances: [:attendance_change_instructor_confirmation, :attendance_change_change_approval])[:attendances]
    # end
    
    # １ヶ月の残業申請確認を扱います。
    def attendance_confirm_one_month_application_user_params
      params.require(:attendance).permit(:id, :confirmation, attendance: [:business_processing, :hour, :min])
    end
    
    # 残業申請の勤怠情報を扱います。
    def update_overtime_application_params
      params.require(:attendance).permit(:id, :confirmation, attendance: [:hour, :min, :tomorrow, :change_application, :business_processing, :to_superior])
    end
    
    # 残業承認の勤怠情報を扱います。
    # def update_overtime_approval_params
    #   params.require(:user).permit(attendances: [:instructor_confirmation, :change_approval])[:attendances]
    # end
    
    # # 所属長承認承認の勤怠情報を扱います。
    # def update_manager_approval_approval_params
    #   params.require(:attendance).permit(attendance: [:manager_approval_instructor_confirmation, :manager_approval_change_approval])
    # end
    
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
