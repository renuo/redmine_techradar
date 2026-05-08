# frozen_string_literal: true

require_relative '../test_helper'

class PluginLoadsTest < ActiveSupport::TestCase
  test 'Technology model loads' do
    assert TechRadar::Technology
  end

  test 'Rating model loads' do
    assert TechRadar::Rating
  end

  test 'Technology table name uses TechRadar prefix' do
    assert_equal 'tech_radar_technologies', TechRadar::Technology.table_name
  end

  test 'Rating table name uses TechRadar prefix' do
    assert_equal 'tech_radar_ratings', TechRadar::Rating.table_name
  end

  test 'TechRadarController loads' do
    assert TechRadarController
  end

  test 'TechRadarRatingsController loads' do
    assert TechRadarRatingsController
  end
end
