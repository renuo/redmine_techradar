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

# turbo-rails mixes ActionCable::TestHelper into every test case, but Redmine
# configures no Action Cable adapter. Point it at the in-memory test adapter so
# the helper's before_setup can build a pubsub.
ActionCable.server.config.cable ||= { 'adapter' => 'test' }
