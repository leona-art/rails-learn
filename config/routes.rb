Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # ユーザー登録
  post '/signup', to: 'users#create'

  # ログイン
  post '/login', to: 'auth#create'

  # プロフィール (保護されたエンドポイント)
  get '/profile', to: 'profile#show'

  # Defines the root path route ("/")
  # root "posts#index"
end
