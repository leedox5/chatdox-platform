Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  get "/chatdox", to: "pages#chatdox", as: :chatdox

  get "/docs", to: "docs#index"
  get "/docs/:id", to: "docs#show", as: :doc
  get "/claudox", to: "claudox_products#show", as: :claudox
  get "/claudox/read", to: "claudox#index", as: :claudox_read
  get "/claudox/read/:id", to: "claudox#show", as: :claudox_chapter
  get "/service-desk", to: "service_desk#index", as: :service_desk
  get "/service-desk/new", to: "service_desk#new", as: :new_service_desk_request
  post "/service-desk", to: "service_desk#create"
  post "/service-desk/export", to: "service_desk#export", as: :service_desk_export
  get "/service-desk/requests/:id", to: "service_desk#show", as: :service_desk_request
  post "/service-desk/requests/:id/jobs", to: "service_desk_jobs#create", as: :service_desk_request_jobs

  post "/service-desk/api/requests", to: "service_desk/api/requests#create", as: :service_desk_api_requests
  get "/service-desk/api/requests", to: "service_desk/api/requests#index"
  get "/service-desk/api/requests/:id", to: "service_desk/api/requests#show", as: :service_desk_api_request
  post "/service-desk/api/requests/:request_id/jobs", to: "service_desk/api/jobs#create", as: :service_desk_api_request_jobs
  get "/dashboard", to: "dashboard#show"
  get "/mypage", to: "mypage#show", as: :mypage
  resources :chapter_progresses, only: :create
  delete "/chapter_progresses", to: "chapter_progresses#destroy"

  get "/getting-started", to: "pages#getting_started"
  get "/pricing", to: "pages#pricing"
  get "/community", to: "pages#community"
  get "/login", to: "pages#login"
  get "/terms", to: "pages#terms"
  get "/privacy", to: "pages#privacy"

  get "/refs", to: "refs#index", as: :refs
  get "/refs/:id", to: "refs#show", as: :ref

  get "/admin/payment-docs", to: redirect("/refs"), as: :admin_payment_docs
  get "/admin/payment-docs/:section", to: redirect("/refs/payment-%{section}"), as: :admin_payment_docs_section

  namespace :admin do
    get "/dashboard", to: "dashboard#show", as: :dashboard
    resources :users, only: %i[index update]
    namespace :commerce do
      resources :orders, only: %i[index show], param: :id do
        post :abandon, on: :member
      end
      resources :refund_requests, only: %i[show update], param: :id
      resources :external_account_links, only: %i[index show], param: :id
      resources :external_access_tasks, only: %i[index show update], param: :id
    end
  end

  resource :github_access, only: %i[show create], controller: :github_access do
    post :change, on: :member
    post :disconnect, on: :member
  end

  get  "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  get  "/billing/success",  to: "billing#success",   as: :billing_success
  post "/billing/success",  to: "billing#success"
  get  "/billing/cancel",   to: "billing#cancel",    as: :billing_cancel
  post "/billing/orders", to: "billing_orders#create", as: :billing_orders
  get "/billing/orders/:id", to: "billing_orders#show", as: :billing_order
  get "/billing/orders/:id/retry", to: "billing_orders#retry_preview", as: :retry_billing_order
  post "/billing/orders/:id/retry", to: "billing_orders#retry", as: :create_retry_billing_order
  get "/billing/orders/:id/refund_request/new", to: "refund_requests#new", as: :new_billing_order_refund_request
  post "/billing/orders/:id/refund_requests", to: "refund_requests#create", as: :billing_order_refund_requests
  get "/refund_requests/:id", to: "refund_requests#show", as: :refund_request

  post "/billing/auths", to: "billing_auths#create", as: :billing_auths
  resources :premium_waitlists, only: :create
  post "/webhooks/toss_payments", to: "webhooks/toss_payments#receive"
  post "/webhooks/portone", to: "webhooks/portone#receive"
end
