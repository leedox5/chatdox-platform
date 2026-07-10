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

  get "/docs", to: "docs#index"
  get "/docs/:id", to: "docs#show", as: :doc
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
  end

  get  "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  get  "/billing/success",  to: "billing#success",   as: :billing_success
  post "/billing/success",  to: "billing#success"
  get  "/billing/cancel",   to: "billing#cancel",    as: :billing_cancel

  post "/billing/auths", to: "billing_auths#create", as: :billing_auths
  resources :premium_waitlists, only: :create
  post "/webhooks/toss_payments", to: "webhooks/toss_payments#receive"
  post "/webhooks/portone", to: "webhooks/portone#receive"
end
