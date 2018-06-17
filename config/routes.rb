TradableAnalysisToolset::Application.routes.draw do
  get 'parameter_groups/edit'

  get 'parameter_groups/new'

  post "charts/index"
  post "tradable_analyzers/index"

#  get "tradable_analyzers/index"

  resources :users
  resources :sessions, :only => [:new, :create, :destroy]
  resources :period_type_specs, :only =>
                                [:new, :create, :edit, :update, :destroy]
  resources :tradable_analyzers, :only =>
                                [:index]

  root :to => 'pages#home'

  get '/help',    :to => 'pages#help'
  get '/about',   :to => 'pages#about'
  get '/signup',  :to => 'users#new'
  get '/signin',  :to => 'sessions#new'
  get '/signout', :to => 'sessions#destroy'
end
