# frozen_string_literal: true

require_relative '../test_helper'

class TechRadarControllerTest < Redmine::ControllerTest
  tests TechRadarController

  fixtures :users, :roles

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

    assert_equal [{ 'name' => 'Ruby', 'can' => 1.0, 'want' => 1.5 }], points
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

    assert_equal [{ 'name' => 'Ruby', 'can' => 0.5, 'want' => 2.0 }], points
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

  def test_index_with_unknown_user_id_returns_unprocessable_entity
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced,    want_level: :yes)

    get :index, params: { user_id: 999_999 }

    assert_response :unprocessable_entity
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
      { 'name' => 'John Smith',    'can' => 1.5, 'want' => 1.0 },
      { 'name' => 'Redmine Admin', 'can' => 0.5, 'want' => 2.0 }
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

  def test_index_with_unknown_technology_id_returns_unprocessable_entity
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced,    want_level: :yes)

    get :index, params: { technology_id: 999_999 }

    assert_response :unprocessable_entity
  end

  def test_index_with_both_user_and_technology_lets_technology_win
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,
                              can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby,
                              can_level: :professional, want_level: :probably_yes)

    get :index, params: { user_id: @admin.id, technology_id: @ruby.id }

    canvas = css_select('canvas[data-controller="scatter-chart"]').first
    points = JSON.parse(canvas['data-scatter-chart-points-value']).sort_by { |p| p['name'] }

    assert_equal ['John Smith', 'Redmine Admin'], points.pluck('name')
  end

  def test_index_shows_technologies_tab_to_user_with_manage_permission
    Role.non_member.add_permission!(:view_tech_radar, :manage_technologies)
    @request.session[:user_id] = @jsmith.id

    get :index

    assert_select '.tabs a[href=?]', tech_radar_technologies_path
  end

  def test_index_hides_technologies_tab_from_user_without_manage_permission
    Role.non_member.add_permission!(:view_tech_radar)
    @request.session[:user_id] = @jsmith.id

    get :index

    assert_response :success
    assert_select '.tabs a[href=?]', tech_radar_technologies_path, count: 0
  end

  def test_index_passes_background_image_to_chart
    get :index

    canvas = css_select('canvas[data-controller="scatter-chart"]').first

    assert_match %r{/tech_radar_background(-\w+)?\.webp\z}, canvas['data-scatter-chart-background-image-value']
  end

  def test_index_renders_ratings_as_plain_table_rows
    rating = TechRadar::Rating.create!(user: @admin, technology: @ruby,
                                       can_level: :advanced, want_level: :probably_yes)
    rating.update_column(:updated_at, Time.zone.local(2026, 3, 4, 12))

    get :index

    headers = css_select('.tech-radar-ratings-table th').map { |th| th.text.strip }
    cells = css_select('.tech-radar-ratings-table tbody tr td').map { |td| td.text.strip }

    assert_equal ['Person', 'Technology', 'Can', 'Want', 'Last edited'], headers
    assert_equal ['Redmine Admin', 'Ruby', 'Advanced', 'Rather yes', '03/04/2026'], cells
  end

  def test_index_with_user_id_narrows_table_to_their_ratings
    TechRadar::Rating.create!(user: @admin,  technology: @ruby,  can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @rails, can_level: :beginner, want_level: :no)

    get :index, params: { user_id: @jsmith.id }

    assert_select '.tech-radar-ratings-table tbody tr', 1
    assert_select '.tech-radar-ratings-table td', text: 'Rails'
  end

  def test_index_summarises_rating_count
    TechRadar::Rating.create!(user: @admin, technology: @ruby,  can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @admin, technology: @rails, can_level: :beginner, want_level: :no)

    get :index

    assert_select '.tech-radar-ratings-summary', text: '2 ratings'
  end

  def test_index_pages_the_table_and_keeps_the_filter
    TechRadar::Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced, want_level: :yes)
    TechRadar::Rating.create!(user: @jsmith, technology: @ruby, can_level: :beginner, want_level: :no)

    with_settings per_page_options: '1,25' do
      get :index, params: { technology_id: @ruby.id, per_page: 1, page: 2 }
    end

    assert_select '.tech-radar-ratings-table tbody tr', 1 do
      assert_select 'td', text: 'John Smith'
    end
    assert_select '.tech-radar-ratings-table .pagination a[href=?]',
                  tech_radar_path(technology_id: @ruby.id, per_page: 1, page: 1), text: '1'
  end

  def test_index_offers_technology_filter_before_person_filter
    get :index

    assert_equal %w[technology_id user_id], css_select('.tech-radar-filters select').pluck('name')
  end

  def test_index_offers_clear_link_when_filtered
    TechRadar::Rating.create!(user: @admin, technology: @ruby, can_level: :advanced, want_level: :yes)

    get :index, params: { technology_id: @ruby.id }

    assert_select '.tech-radar-filters a[href=?]', tech_radar_path, text: 'Clear'
  end

  def test_index_offers_no_clear_link_when_unfiltered
    get :index

    assert_select '.tech-radar-filters a[href=?]', tech_radar_path, count: 0
  end

  def test_index_shows_no_data_when_nothing_to_list
    get :index

    assert_select '.tech-radar-ratings-table table', 0
    assert_select '.tech-radar-ratings-table .nodata'
  end
end
