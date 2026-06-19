# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'tech_radar', to: 'tech_radar#index', as: :tech_radar

get 'tech_radar/ratings', to: 'tech_radar_ratings#index', as: :tech_radar_ratings
patch 'tech_radar/ratings/:technology_id',
      to: 'tech_radar_ratings#save', as: :save_tech_radar_rating

get 'tech_radar/rate', to: 'tech_radar_ratings#rate', as: :tech_radar_rating

get   'tech_radar/rate/:technology_id', to: 'tech_radar_ratings#show', as: :tech_radar_rate_technology
patch 'tech_radar/rate/:technology_id', to: 'tech_radar_ratings#update'
