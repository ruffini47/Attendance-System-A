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
  get '/bases', to: 'bases#index'
  post '/bases', to: 'bases#create'
  
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
