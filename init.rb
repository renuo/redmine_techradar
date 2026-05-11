# frozen_string_literal: true

require File.expand_path('lib/redmine_techradar/hooks', __dir__)

plugin_importmap = File.expand_path('config/importmap.rb', __dir__)
Rails.application.config.importmap.paths << plugin_importmap
Rails.application.importmap.draw(plugin_importmap)

Redmine::Plugin.register :redmine_techradar do
  name 'Redmine Techradar plugin'
  author 'Brendan Minder'
  description 'A Techradar plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/renuo/redmine_techradar'
  author_url 'https://github.com/ddbrendan'

  permission :view_tech_radar,
             { tech_radar: [:index] },
             global: true,
             require: :loggedin
  permission :rate_technologies,
             { tech_radar_ratings: [:show, :update, :skip, :back] },
             global: true,
             require: :loggedin

  menu :top_menu, :tech_radar_rate,
       { controller: 'tech_radar_ratings', action: 'show' },
       caption: :label_tech_radar_rate,
       if: ->(_) { User.current.allowed_to?(:rate_technologies, nil, global: true) }
end
