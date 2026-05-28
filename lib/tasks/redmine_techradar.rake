# frozen_string_literal: true

namespace :redmine_techradar do
  desc 'Run redmine_techradar plugin checks'
  task check: :environment do
    sh 'RAILS_ENV=test bundle exec rake redmine:plugins:test NAME=redmine_techradar'
  end

  desc 'Load redmine_techradar plugin seed data'
  task seed: :environment do
    load Rails.root.join('plugins/redmine_techradar/db/seeds.rb')
  end
end
