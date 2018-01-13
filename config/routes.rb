Rails.application.routes.draw do
  resources :users, only: [:new, :create, :edit]
  resources :user_sessions, only: [:create, :destroy]
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :active_requests, only: [:new, :edit]
  
  get '/dashboard/index', to: 'dashboard#index'
  post '/dashboard/layouts/:partial', to: 'jquery#dashboard_options'
  get '/dashboard/payments_details', to: 'jquery#payments_details'
  get 'dashboard/layouts/:partial', to: 'static_pages#partial'
  get '/dashboard/info/getwallets', to: 'jquery#get_wallets'
  get '/dashboard/info/getpayments', to: 'jquery#get_payments'
  get '/dashboard/info/getpayment/:id', to: 'jquery#render_payment'
  get '/dashboard/info/get_withdrawal_details/:id', to: 'jquery#render_withdrawal_details'
  post '/dashboard/withdrawal/cancel/:id', to: 'jquery#cancel_withdrawal'
  post 'dashboard/confirmar_deposito', to: 'admin#confirm_saldo'
  post 'dashboard/register_users', to: 'admin#register_users'
  get '/dashboard/instant_buy_price/:coin1/:coin2/:tipo', to: 'api#instant_buy_price'
  get '/dashboard/overview/wallets/:currency', to: 'dashboard#wallets_view'
  patch '/dashboard/changepasswd', to: 'password_resets#change_pass'
  
  
  get '/exchange/pair/:coin1/:coin2', to: 'exchange#render_orders'
  post '/exchange/pair/:coin1/:coin2', to: 'exchange#create_order'
  post '/exchange/order/cancel/:id', to: 'exchange#cancel_order'
  get '/exchange/open_orders', to: 'exchange#open_orders'
  post '/exchange/instant', to: 'exchange#instant'
  post '/deposit/new', to: 'exchange#deposit_new'
  get '/deposit/verify/:id', to: 'static_pages#deposit_form'
  post '/deposit/verify/new', to: 'dashboard#deposit_verify'
  

  post '/active_requests/new', to: 'users#active_request_new'
#aliases
  get '/sign_out', to: 'user_sessions#destroy', as: :sign_out
  get '/sign_in', to: 'user_sessions#new', as: :sign_in
  
  post '/users/new', to: 'users#create'
  post '/cpay', to: 'jquery#coinpayments_deposit'
  
  get '/withdrawal/form/:currency', to: 'jquery#withdrawal_get'
  get '/withdrawal/:code', to: 'static_pages#withdrawal'
  
  get '/api/is_valid_address/:currency/:address', to: 'api#test_address'
  get '/request_detail/:request_id', to: 'admin#request_details'
  post '/admin/activation', to: 'admin#active_account'
  
  
  mount ActionCable.server => '/cable'
  
  post '/contact', to: 'jquery#contact_email'
  root to: 'static_pages#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
