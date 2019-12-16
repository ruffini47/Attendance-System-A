class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  
  $days_of_the_week = %w{日 月 火 水 木 金 土}

  # beforeフィルター
    
  # paramsハッシュからユーザーを取得します。
  def set_user
    @user = User.find(params[:id])
  end
    
  # ログイン済みのユーザーか確認します。
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
    end
  end
    
  # アクセスしたユーザーが現在ログインしているユーザーか確認します。
  def correct_user
    unless current_user?(@user)
      flash[:danger] = "編集権限がありません。"
      redirect_to(root_url)
    end
  end

  # システム管理権限所有かどうか判定します。
  def admin_user
    unless current_user.admin?
      flash[:danger] = "編集権限がありません。"
      redirect_to root_url
    end
  end

  # システム管理権限所有でないかどうか判定します。
  def not_admin_user
    if current_user.admin?
      flash[:danger] = "編集権限がありません。"
      redirect_to root_path
    end
  end

  # beforeフィルター
    
  # ページ出力前に1ヶ月分のデータの存在を確認・セットします。
  def set_one_month
    if params[:date].nil?
      @first_day = Date.current.beginning_of_month
    else
      @first_day = params[:date].to_date
    end
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day] # 対象の月の日数を代入します。
    # ユーザーに紐付く一ヶ月分のレコードを検索し取得します。
    # confirm_one_month 経由でset_one_monthを呼んだときに@userをセットする。
    @user = User.find(params[:user_id]) if @user.nil?
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    
    unless one_month.count == @attendances.count # それぞれの件数（日数）が一致するか評価します。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
      end
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end


  def set_one_month_2
    if params[:date].nil?
      @first_day = Date.current.beginning_of_month
    else
      @first_day = params[:date].to_date
    end
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day] # 対象の月の日数を代入します。
    # ユーザーに紐付く一ヶ月分のレコードを検索し取得します。
    # confirm_one_month 経由でset_one_monthを呼んだときに@userをセットする。
    @user = User.find(params[:id]) if @user.nil?
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    
    unless one_month.count == @attendances.count # それぞれの件数（日数）が一致するか評価します。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
      end
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end
  
end