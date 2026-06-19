# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'tech_radar', to: 'tech_radar#index', as: :tech_radar

get 'tech_radar/ratings', to: 'tech_radar_ratings#index', as: :tech_radar_ratings
patch 'tech_radar/ratings/:technology_id',
      to: 'tech_radar_ratings#save', as: :save_tech_radar_rating

resource :tech_radar_rating,
         only: [:show, :update],
         path: 'tech_radar/rate',
         controller: 'tech_radar_ratings' do
  post :skip
  post :back
end
