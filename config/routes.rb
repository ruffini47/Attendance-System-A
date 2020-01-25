Rails.application.routes.draw do
  
  #get 'bases/new'

  root 'static_pages#home'

  # ユーザー作成
  get '/signup', to: 'users#new'
  
  # ログイン機能
  
  # ログインページ表示
  get '/login', to: 'sessions#new'
  
  # ログイン情報送信
  post '/login', to: 'sessions#create'

  # ログアウト
  delete '/logout', to: 'sessions#destroy'
  
  # 出勤中社員一覧
  get '/at_work', to: 'attendances#at_work'

  # 勤怠ログ
  get '/users/:id/attendance/time_log/', to: 'attendances#time_log', as: 'attendances_time_log_user'
  post '/users/:id/attendance/time_log/', to: 'attendances#update_time_log'
   # 勤怠ログのリセットボタン
  get '/users/:id/attendance/reset_time_log', to: 'attendances#reset_time_log', as:'attendances_reset_time_log'
  # 拠点情報
  resources :bases do
  
  end
  
  # 残業申請
  get '/users/:user_id/attendances/:id/overtime_application/', to: 'attendances#edit_overtime_application', as: 'attendances_overtime_application_user'
  patch '/users/:user_id/attendances/:id/overtime_application/', to: 'attendances#update_overtime_application'
  # 残業申請_1カ月勤怠確認
  get '/users/:user_id/attendance/:id/confirm_one_month_application/', to: 'attendances#confirm_one_month_application', as: 'attendance_confirm_one_month_application_user'
  get '/users/:user_id/attendance/:id/confirm_one_month_approval/', to: 'attendances#confirm_one_month_approval', as: 'attendance_confirm_one_month_approval_user'
  # 残業承認
  get '/users/:id/attendance/overtime_approval/', to: 'attendances#edit_overtime_approval', as: 'attendances_overtime_approval_user'
  patch '/users/:id/attendance/overtime_approval/', to: 'attendances#update_overtime_approval'

  # 勤怠変更承認
  get '/users/:id/attendance/attendance_change_approval/', to: 'attendances#edit_attendance_change_approval', as: 'attendances_attendance_change_approval_user'
  patch '/users/:id/attendance/attendance_change_approval/', to: 'attendances#update_attendance_change_approval'

  # 勤怠変更_1カ月勤怠確認
  get '/users/:user_id/attendance/:id/confirm_one_month_attendance_change_approval/', to: 'attendances#confirm_one_month_attendance_change_approval', as: 'attendance_confirm_one_month_attendance_change_approval_user'

  # 残業申請承認確認画面のキャンセル処理
  get '/users/:id/cancel/', to: 'attendances#cancel_confirm_one_month', as:'attendances_cancel_confirm_one_month'
  # 勤怠変更確認画面のキャンセル処理
  get '/users/:id/cancel_attendance_change/', to: 'attendances#cancel_attendance_change_confirm_one_month', as:'attendances_cancel_attendance_change_confirm_one_month'
  # 所属長承認確認画面のキャンセル処理
  get '/users/:id/cancel_manager_approval/', to: 'attendances#cancel_manager_approval_confirm_one_month', as:'attendances_cancel_manager_approval_confirm_one_month'

  # 所属長承認申請
  post '/users/:id/attendance/attendance_manager_approval_appication/', to: 'attendances#post_manager_approval_application', as: 'attendances_manager_approval_application_user'
  
  # 所属長承認モーダル
  get '/users/:id/attendance/attendance_manager_approval_approval/', to: 'attendances#edit_manager_approval_approval', as: 'attendances_manager_approval_approval_user'             
  patch '/users/:id/attendance/attendance_manager_approval_approval/', to: 'attendances#update_manager_approval_approval' 
  
  # 所属長承認_1カ月勤怠確認  
  get '/users/:user_id/attendance/:id/confirm_one_month_manager_approval_approval/', to: 'attendances#confirm_one_month_manager_approval_approval', as: 'attendance_confirm_one_month_manager_approval_approval_user'
  
  resources :users do
      
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
    end
    resources :attendances, only: :update
    
    collection { post :import }
    
  end
end
