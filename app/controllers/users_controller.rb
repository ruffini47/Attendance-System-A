class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :edit_basic_info, :update_basic_info, :destroy]
  before_action :logged_in_user, only: [:show, :index, :edit, :update, :edit_basic_info, :update_basic_info, :destroy, :import]
  #before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :edit_basic_info, :update_basic_info, :destroy, :import]
  before_action :not_admin_user, only: [:show, :edit, :update]
  #before_action :admin_or_correct_user, only: :show
  before_action :set_one_month, only: :show

  def index
    @users = User.where.not(id: current_user.id)
  end
  
  def import
    #fileはtmpに自動で一時保存される
    User.import(params[:file])
    redirect_to users_url
  end
  
  def show
    @last_attendance = Attendance.find_by(user_id:@user.id, worked_on:@last_day)
    @worked_sum = @attendances.where.not(finished_at: nil).count
    
    respond_to do |format|
      format.any
      format.csv do
        send_data render_to_string, filename: "#{@user.name}の#{@attendances.first.worked_on.month}月の勤怠.csv", type: :csv
      end
    end
    
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit      
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "「#{@user.name}」のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "基本情報を更新しました。"
      unless  @user.admin?
        redirect_to @user
      else
        redirect_to root_url
      end
    else
      render :edit_basic_info  
    end
    
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid,
                                    :basic_work_time, :designated_work_start_time, :designated_work_end_time,
                                    :password, :password_confirmation)
    end

    def basic_info_params
      params.require(:user).permit(:basic_time, :work_time)
    end
    
    # beforeフィルター
    
    # 管理者権限、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
#      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end
