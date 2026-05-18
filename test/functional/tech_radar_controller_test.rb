# frozen_string_literal: true

require_relative '../test_helper'

class TechRadarControllerTest < Redmine::ControllerTest
  tests TechRadarController

  fixtures :users

  def setup
    User.current = nil
    @admin = User.find_by(login: 'admin')
    @jsmith = User.find_by(login: 'jsmith')
    @request.session[:user_id] = @admin.id
    @ruby = TechRadar::Technology.create!(name: 'Ruby')
    @rails = TechRadar::Technology.create!(name: 'Rails')
  end

  def test_index_renders_scatter_canvas
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_response :success
    assert_select 'canvas[data-controller="scatter-chart"]'
  end

  def test_index_serialises_centroids_into_canvas_data_attribute
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)

    get :index

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value'])

    assert_equal [{ 'name' => 'Ruby', 'can' => 3.5, 'want' => 4.5 }], points
  end

  def test_index_redirects_anonymous_user_to_login
    @request.session[:user_id] = nil

    get :index

    assert_redirected_to %r{/login}
  end

  def test_index_forbidden_for_user_without_view_permission
    @request.session[:user_id] = @jsmith.id

    get :index

    assert_response :forbidden
  end

  def test_index_with_user_id_serialises_only_that_users_points
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :beginner, want_level: :neutral)

    get :index, params: { user_id: @admin.id }

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value'])

    assert_equal [{ 'name' => 'Ruby', 'can' => 3.0, 'want' => 5.0 }], points
  end

  def test_index_filter_dropdown_lists_only_users_with_ratings
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index

    options = css_select('select[name="user_id"] option').pluck('value')

    assert_includes options, @admin.id.to_s
    assert_not_includes options, @jsmith.id.to_s
  end

  def test_index_filter_dropdown_marks_selected_user_id
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index, params: { user_id: @admin.id }

    selected = css_select('select[name="user_id"] option[selected]').first

    assert_equal @admin.id.to_s, selected['value']
  end

  def test_index_with_unknown_user_id_falls_back_to_centroids
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced,    want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)

    get :index, params: { user_id: 999_999 }

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value'])

    assert_equal [{ 'name' => 'Ruby', 'can' => 3.5, 'want' => 4.5 }], points
  end

  def test_index_with_technology_id_serialises_one_point_per_rater
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)
    TechRadar::Rating.create!(user: @admin,  technology: @rails,
                              can_level: :beginner, want_level: :neutral)

    get :index, params: { technology_id: @ruby.id }

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value']).sort_by { |p| p['name'] }

    assert_equal [
      { 'name' => 'admin',  'can' => 3.0, 'want' => 5.0 },
      { 'name' => 'jsmith', 'can' => 4.0, 'want' => 4.0 }
    ], points
  end

  def test_index_filter_dropdown_lists_only_technologies_with_ratings
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index

    options = css_select('select[name="technology_id"] option').pluck('value')

    assert_includes options, @ruby.id.to_s
    assert_not_includes options, @rails.id.to_s
  end

  def test_index_filter_dropdown_marks_selected_technology_id
    TechRadar::Rating.create!(user: @admin, technology: @ruby,
                              can_level: :advanced, want_level: :yes)

    get :index, params: { technology_id: @ruby.id }

    selected = css_select('select[name="technology_id"] option[selected]').first

    assert_equal @ruby.id.to_s, selected['value']
  end

  def test_index_with_unknown_technology_id_falls_back_to_centroids
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced,    want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)

    get :index, params: { technology_id: 999_999 }

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value'])

    assert_equal [{ 'name' => 'Ruby', 'can' => 3.5, 'want' => 4.5 }], points
  end

  def test_index_with_both_user_and_technology_lets_technology_win
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)

    get :index, params: { user_id: @admin.id, technology_id: @ruby.id }

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value']).sort_by { |p| p['name'] }

    assert_equal %w[admin jsmith], points.pluck('name')
  end
end
