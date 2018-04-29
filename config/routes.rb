Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root to: redirect(path: '/matches')

  namespace :api, defaults: { format: 'json' } do
    namespace :v1 do
      #resources :host_machines
      #resources :servers
      #resources :matches
    end
    namespace :v2 do
      resources :matches, defaults: { format: 'json' }
      post '/servers/:id', to: 'servers#update'
    end
  end
  get 'matches/' => 'matches#index'
  get 'events/' => 'event_logs#index', defaults: {format: 'json'}

  require "sidekiq/web"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == 'evlbr' && password == 'serveropsonly'
  end if true
  mount Sidekiq::Web, at: "/sidekiq"
end
