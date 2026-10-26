# frozen_string_literal: true

require 'simplecov'

SimpleCov.root File.expand_path('..', __dir__)
SimpleCov.start do
  enable_coverage :branch
  track_files '**/*.rb'
  add_filter '/test/'
  add_filter '/db/'
  add_filter '/config/'
  minimum_coverage line: 100, branch: 100
end

require File.expand_path('../../../test/test_helper', __dir__)

module TechRadarTestHelpers
  # Makes the principal (user or group) a rater through a membership in its own
  # project, so it never collides with memberships from Redmine's fixtures
  def grant_rating_role(principal)
    role = Role.create!(name: "Rater #{principal.id}", permissions: [:rate_technologies])
    project = Project.find_or_create_by!(name: 'Tech Radar raters', identifier: 'tech-radar-raters')
    Member.create!(principal: principal, project: project, role_ids: [role.id])
  end
end
