# frozen_string_literal: true

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
end
