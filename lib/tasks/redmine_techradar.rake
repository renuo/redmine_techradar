namespace :redmine_techradar do
  desc "Run redmine_techradar plugin checks"
  task check: :environment do
    sh "RAILS_ENV=test bundle exec rake redmine:plugins:test NAME=redmine_techradar"
  end
end
