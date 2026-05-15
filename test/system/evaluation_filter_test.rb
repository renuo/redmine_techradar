# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../../test/application_system_test_case'

class EvaluationFilterTest < ApplicationSystemTestCase
  fixtures :users

  def setup
    super
    @admin = User.find_by(login: 'admin')
    @jsmith = User.find_by(login: 'jsmith')
    @ruby = TechRadar::Technology.create!(name: 'Ruby')
    @rails = TechRadar::Technology.create!(name: 'Rails')

    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @admin, technology: @rails,
                              can_level: :beginner, want_level: :neutral)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)
  end

  def teardown
    TechRadar::Rating.delete_all
    TechRadar::Technology.delete_all
    super
  end

  def test_filtering_by_person_restricts_chart_to_their_ratings
    log_user('admin', 'admin')
    visit '/tech_radar'

    select 'jsmith', from: 'user_id'

    assert_chart_labels %w[Ruby]
  end

  def test_filter_selection_appears_in_url
    log_user('admin', 'admin')
    visit '/tech_radar'

    select 'admin', from: 'user_id'

    assert_current_path(/user_id=#{@admin.id}/)
  end

  def test_filtering_by_technology_shows_one_point_per_rater
    log_user('admin', 'admin')
    visit '/tech_radar'

    select 'Ruby', from: 'technology_id'

    assert_chart_labels %w[admin jsmith]
  end

  def test_technology_filter_selection_appears_in_url
    log_user('admin', 'admin')
    visit '/tech_radar'

    select 'Ruby', from: 'technology_id'

    assert_current_path(/technology_id=#{@ruby.id}/)
  end

  private

  def assert_chart_labels(expected)
    canvas = find('canvas[data-controller="scatter-chart"]')
    points = JSON.parse(canvas['data-scatter-chart-points-value'])

    assert_equal expected.sort, points.pluck('name').sort
  end
end
