# frozen_string_literal: true

namespace :redmine_techradar do
  desc 'Load redmine_techradar plugin seed data'
  task seed: :environment do
    load Rails.root.join('plugins/redmine_techradar/db/seeds.rb')
  end
end
