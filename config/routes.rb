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

  root to: 'pages#index'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
