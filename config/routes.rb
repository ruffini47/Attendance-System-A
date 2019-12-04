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


# 拠点情報
  resources :bases do
  
  end
  
# 残業申請
  get '/users/:user_id/attendances/:id/overtime_application/', to: 'attendances#edit_overtime_application', as: 'attendances_overtime_application_user'
  patch '/users/:user_id/attendances/:id/overtime_application/', to: 'attendances#update_overtime_application'

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
