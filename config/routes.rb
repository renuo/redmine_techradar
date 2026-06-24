# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'tech_radar', to: 'tech_radar#index', as: :tech_radar

namespace :tech_radar do
  resources :ratings, only: [:index], param: :technology_id do
    patch :save, on: :member
  end
end

get 'tech_radar/rate', to: 'tech_radar/ratings#rate', as: :tech_radar_rating

get   'tech_radar/rate/:technology_id', to: 'tech_radar/ratings#show', as: :tech_radar_rate_technology
patch 'tech_radar/rate/:technology_id', to: 'tech_radar/ratings#update'
