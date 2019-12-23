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

  # 確認画面のキャンセル処理
  get '/users/:id/cancel/', to: 'attendances#cancel_confirm_one_month', as:'attendances_cancel_confirm_one_month'

# 拠点情報
  resources :bases do
  
  end
  
# 残業申請
  get '/users/:user_id/attendances/:id/overtime_application/', to: 'attendances#edit_overtime_application', as: 'attendances_overtime_application_user'
  patch '/users/:user_id/attendances/:id/overtime_application/', to: 'attendances#update_overtime_application'
# 残業申請_1カ月勤怠確認
  get '/users/:user_id/attendance/:id/confirm_one_month_application/:hour/:min/', to: 'attendances#confirm_one_month_application', as: 'attendance_confirm_one_month_application_user'
  get '/users/:user_id/attendance/:id/confirm_one_month_approval/', to: 'attendances#confirm_one_month_approval', as: 'attendance_confirm_one_month_approval_user'
# 残業承認
  get '/users/:id/attendance/overtime_approval/', to: 'attendances#edit_overtime_approval', as: 'attendances_overtime_approval_user'
  patch '/users/:id/attendance/overtime_approval/', to: 'attendances#update_overtime_approval'
  
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
