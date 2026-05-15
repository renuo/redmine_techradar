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

  menu :top_menu, :tech_radar,
       { controller: 'tech_radar', action: 'index' },
       caption: :label_tech_radar,
       if: ->(_) { User.current.allowed_to?(:view_tech_radar, nil, global: true) }
end
