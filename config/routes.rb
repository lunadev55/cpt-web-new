Rails.application.routes.draw do
  resources :users, only: [:new, :create, :edit]

  resources :user_sessions, only: [:create, :destroy]

  resources :password_resets, only: [:new, :create, :edit, :update]
  get '/dashboard/index', to: 'dashboard#index'

  get '/sign_out', to: 'user_sessions#destroy', as: :sign_out
  get '/sign_in', to: 'user_sessions#new', as: :sign_in
  get 'dashboard/layouts/:partial', to: 'pages#partial'
  post '/users/new', to: 'users#create'
  post '/dashboard/layouts/:partial', to: 'jquery#dashboard_options'
  get '/dashboard/payments_details', to: 'jquery#payments_details'
  
  post '/cpay', to: 'jquery#coinpayments_deposit'
  
  get '/dashboard/info/getwallets', to: 'jquery#get_wallets'
  get '/dashboard/info/getpayments', to: 'jquery#get_payments'
  get '/dashboard/info/getpayment/:id', to: 'jquery#render_payment'
  get '/dashboard/info/get_withdrawal_details/:id', to: 'jquery#render_withdrawal_details'
  
  post '/dashboard/withdrawal/cancel/:id', to: 'jquery#cancel_withdrawal'
  
  get '/withdrawal/form/:currency', to: 'jquery#withdrawal_get'
  get '/withdrawal/:code', to: 'pages#withdrawal'
  
  get '/api/is_valid_address/:currency/:address', to: 'api#test_address'
  
  get '/exchange/pair/:coin1/:coin2', to: 'exchange#render_orders'
  post '/exchange/pair/:coin1/:coin2', to: 'exchange#create_order'
  post '/exchange/order/cancel/:id', to: 'exchange#cancel_order'
  get '/exchange/open_orders', to: 'exchange#open_orders'
  get '/dashboard/overview/wallets/:currency', to: 'dashboard#wallets_view'
  post '/contact', to: 'jquery#contact_email'
  patch '/dashboard/changepasswd', to: 'password_resets#change_pass'

  root to: 'pages#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
