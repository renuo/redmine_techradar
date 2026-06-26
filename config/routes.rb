# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'tech_radar', to: 'tech_radar#index', as: :tech_radar

namespace :tech_radar do
  resources :ratings, only: [:index, :show, :update], param: :technology_id do
    get :rate, on: :collection
  end
end
