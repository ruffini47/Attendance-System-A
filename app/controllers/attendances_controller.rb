class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month, :confirm_one_month]
  before_action :not_admin_user, only: [:edit_one_month, :update_one_month]
  
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
  end
  
  def update_overtime_application
    #require "date"
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @attendance.overtime_applying = true
    d = DateTime.now
    year = d.year
    mon = d.month
    day = d.day
    hour = params[:attendance][:hour].to_i
    min = params[:attendance][:min].to_i
    d1 = DateTime.new(year, mon, day, hour, min, 0, 0.375);
    @attendance.scheduled_end_time = d1
    tomorrow = params[:attendance][:tomorrow]
    business_processing = params[:attendance][:business_processing]
    @attendance.business_processing = business_processing
    @attendance.save
    to_superior = params[:attendance][:to_superior]
    user = User.find(to_superior)
    user.number_of_overtime_applied += 1
    user.save
    
  end
  
  def confirm_one_month
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    
    redirect_to(user_url(@user.id))
  end
  
  def edit_overtime_approval
    @users = User.all
    @attendances = Attendance.all
    
    @i = 0
    @j = 0
    @user_id = []
    @attendance_m = [][]
    hit = false
    
    i_max = 0
    jj = 0
    j_max = 0
    
    @attendances.each do |attendance|
      if attendance.overtime_applying == true
        @user_id.each do |user_id|
          if attendance.user_id == user_id
            hit = true        
          end
        end
        if hit == false
          i_max += 1
          jj = 0
        end
        jj += 1
        j_max[i_max] = 
        hit = false
      end
    end
    
    
    
    @i = 0
    @j[0] = 0
    
    @attendances.each do |attendance|
      if attendance.overtime_applying == true
        @user_id.each do |user_id|
          if attendance.user_id == user_id
            hit = true        
          end
        end
        if hit == false
          @user_id[@i] = attendance.user_id
          @i += 1
          @j[@i] = 0
        end
        @attendance_m[@i,@j] = attendance
        @j[@i] += 1
        hit = false
      end
    end
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
