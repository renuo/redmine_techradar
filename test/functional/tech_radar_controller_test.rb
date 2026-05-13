# frozen_string_literal: true

require_relative '../test_helper'

class TechRadarControllerTest < Redmine::ControllerTest
  tests TechRadarController

  fixtures :users

  def setup
    User.current = nil
    @request.session[:user_id] = 1
    @ruby = TechRadar::Technology.create!(name: 'Ruby')
    @rails = TechRadar::Technology.create!(name: 'Rails')
  end

  def teardown
    TechRadar::Rating.delete_all
    TechRadar::Technology.delete_all
  end

  def test_index_renders_scatter_canvas
    TechRadar::Rating.create!(user_id: 1, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_response :success
    assert_select 'canvas[data-controller="scatter-chart"]'
  end

  def test_index_renders_nav_with_evaluation_marked_active
    get :index

    assert_select 'ul.tech-radar-nav li.active a', text: 'Evaluation'
    assert_select 'ul.tech-radar-nav li:not(.active) a', text: 'Rate'
  end

  def test_index_serialises_centroids_into_canvas_data_attribute
    TechRadar::Rating.create!(user_id: 1, technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user_id: 2, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)

    get :index

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value'])

    assert_equal [{ 'id' => @ruby.id, 'name' => 'Ruby', 'can' => 3.5, 'want' => 4.5 }], points
  end

  def test_index_redirects_anonymous_user_to_login
    @request.session[:user_id] = nil

    get :index

    assert_redirected_to %r{/login}
  end
end
