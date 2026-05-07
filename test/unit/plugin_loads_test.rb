# frozen_string_literal: true

require_relative '../test_helper'

class PluginLoadsTest < ActiveSupport::TestCase
  test 'plugin classes load' do
    assert TechRadar::Technology
    assert TechRadar::Rating
    assert TechRadarController
    assert TechRadarRatingsController
  end
end
