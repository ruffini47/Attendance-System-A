class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month, :edit_overtime_application, :update_overtime_application,
                                        :edit_overtime_approval, :update_overtime_approval]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month, :edit_overtime_application,
                                               :update_overtime_application]
  before_action :set_one_month, only: [:edit_one_month, :confirm_one_month_application, :confirm_one_month_approval]
  before_action :set_one_month_2, only: [:update_overtime_approval]
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

    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
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
    @attendance.overtime_applying = true 
    

    hour = params[:attendance][:hour].to_i
    min = params[:attendance][:min].to_i
    
    
    
    
    
    # 共通の処理終わり
    ##########################################################
    
    
    
    
    ##########################################################
    # 勤怠を確認ボタン押下後の処理
    if params[:confirmation] == "確認"
      
      business_processing = params[:attendance][:business_processing]
      @attendance.cl_business_processing = business_processing
      @attendance.save
      
      
      redirect_to attendance_confirm_one_month_application_user_url(@user.id, @attendance.id, hour, min, date: @first_day) and return
    
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
    # userは申請先ユーザ
    user = User.find(to_superior)
    user.number_of_overtime_applied += 1
    if @attendance.result.nil?
      @attendance.result = "#{user.name}へ残業申請中"
    else
      @attendance.result.insert(0,"#{user.name}へ残業申請中")
    end
    #attendance[i].result.insert(0,result[i])
    # 申請元@attendanceに申請先user.idの値を持たせるカラムto_superior_user_id
    @attendance.to_superior_user_id = user.id
    
    
    
   
    if change_application == 1
      user.save
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
    scheduled_end_time_hour = []
    scheduled_end_time_min = []
    #result[i]はi番目の"なし","申請中","承認","否認"などの結果文字列
    for i in 0..n-1 do
      result[i] = inst_hash.invert[instructor_confirmation[i]]
    end
    for i in 0..n-1 do
      if instructor_confirmation[i] == 2
        result[i] = "残業承認済"
      elsif instructor_confirmation[i] == 3
        result[i] = "残業否認"
      else
        result[i] = ""
      end
    end
      
    for i in 0..n-1 do
      # 残業承認済み削除ループ
      #loop do
      #  if !attendance[i].result.nil?
      #    if attendance[i].result.include?("残業承認済")
      #      attendance[i].result.slice!("残業承認済")
      #    else
      #      break
      #    end
      #  else
      #    break
      #  end
      #end
        # 残業否認削除ループ
      #loop do
      #  if !attendance[i].result.nil?
      #    if attendance[i].result.include?("残業否認")
      #      attendance[i].result.slice!("残業否認")
      #    else
      #      break
      #    end
      #  else
      #    break
      #  end
      #end
          
      if (instructor_confirmation[i] == 2 || instructor_confirmation[i] == 3) && change_approval[i] == "true" 
        
        @user.number_of_overtime_applied -= 1
        attendance[i].overtime_applying = false
        attendance[i].business_processing = attendance[i].temp_business_processing
        attendance[i].temp_business_processing = nil
        attendance[i].scheduled_end_time = attendance[i].temp_scheduled_end_time
        attendance[i].temp_scheduled_end_time = nil
        if attendance[i].result.nil?
          attendance[i].result = result[i]  
        elsif attendance[i].result.include?("#{@user.name}へ残業申請中")
          attendance[i].result.delete!("#{@user.name}へ残業申請中")
          attendance[i].result.insert(0,result[i])
        end
      end
      
      @user.save
      attendance[i].save
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
  
  
  
  private
  
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
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
