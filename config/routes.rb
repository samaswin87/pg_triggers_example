Rails.application.routes.draw do
  mount PgSqlTriggers::Engine => "/pg_sql_triggers"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Trigger testing UI
  root "trigger_tests#index"
  resources :trigger_tests, only: [:index] do
    collection do
      post :test_user_email
      post :test_post_slug
      post :test_order_total
      post :test_order_status
      post :test_comment_count
      post :test_audit_logging
      post :toggle_trigger
    end
  end
end
