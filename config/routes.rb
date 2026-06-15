# frozen_string_literal: true

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'tech_radar', to: 'tech_radar#index', as: :tech_radar

# Entry point: redirect to the first unrated technology, or render the done state.
get 'tech_radar/rate', to: 'tech_radar_ratings#index', as: :tech_radar_rating

# One URL per technology being rated, so the browser history is the back-stack.
get   'tech_radar/rate/:technology_id', to: 'tech_radar_ratings#show', as: :tech_radar_rate_technology
patch 'tech_radar/rate/:technology_id', to: 'tech_radar_ratings#update'
