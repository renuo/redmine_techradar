# frozen_string_literal: true

require_relative '../../test_helper'

class TechRadar::RatingsControllerTest < Redmine::ControllerTest
  tests TechRadar::RatingsController

  fixtures :users

  def setup
    User.current = nil
    @admin = User.find_by(login: 'admin')
    @request.session[:user_id] = @admin.id
    @t1 = TechRadar::Technology.create!(name: 'Ruby')
    @t2 = TechRadar::Technology.create!(name: 'Rails')
  end

  def test_index_lists_all_technologies
    get :index

    assert_response :success
    assert_select '.tech-radar-rating-name', text: 'Ruby'
    assert_select '.tech-radar-rating-name', text: 'Rails'
  end

  def test_index_preselects_current_users_rating
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_select "form[action=?] select[name=?] option[selected][value=?]",
                  save_tech_radar_rating_path(@t1), 'rating[can_level]', 'advanced'
    assert_select "form[action=?] select[name=?] option[selected][value=?]",
                  save_tech_radar_rating_path(@t1), 'rating[want_level]', 'yes'
  end

  def test_index_does_not_preselect_another_users_rating
    jsmith = User.find_by(login: 'jsmith')
    TechRadar::Rating.create!(user: jsmith, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_response :success
    assert_select "form[action=?] option[selected]",
                  save_tech_radar_rating_path(@t1), count: 0
  end

  def test_index_orders_technologies_by_id
    get :index

    rows = css_select('.tech-radar-ratings form .tech-radar-rating-name')

    assert_equal %w[Ruby Rails], rows.map { |span| span.text.strip }
  end

  def test_index_preselects_only_the_rated_rows
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_select "form[action=?] select[name=?] option[selected][value=?]",
                  save_tech_radar_rating_path(@t1), 'rating[can_level]', 'advanced'
    assert_select "form[action=?] option[selected]",
                  save_tech_radar_rating_path(@t2), count: 0
  end

  def test_index_paginates_technologies
    with_settings per_page_options: '1,25,50' do
      get :index, params: { per_page: 1, page: 2 }
    end

    assert_response :success
    assert_select '.tech-radar-rating-name', text: 'Rails'
    assert_select '.tech-radar-rating-name', text: 'Ruby', count: 0
  end

  def test_index_renders_pagination_controls_for_multiple_pages
    with_settings per_page_options: '1,25,50' do
      get :index, params: { per_page: 1 }
    end

    assert_select 'span.pagination a', text: '2'
  end

  def test_save_creates_rating_and_redirects
    patch :save, params: { technology_id: @t1.id,
                           rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_ratings_path
    rating = TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)

    assert_equal 'advanced', rating.can_level
    assert_equal 'yes', rating.want_level
  end

  def test_save_preserves_the_current_page
    patch :save, params: { technology_id: @t1.id, page: 2,
                           rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_ratings_path(page: 2)
  end

  def test_save_updates_existing_rating_without_adding_a_row
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :beginner, want_level: :no)

    patch :save, params: { technology_id: @t1.id,
                           rating: { can_level: 'professional', want_level: 'yes' } }

    ratings = TechRadar::Rating.where(user_id: @admin.id, technology: @t1)

    assert_equal 1, ratings.count
    assert_equal 'professional', ratings.first.can_level
    assert_equal 'yes', ratings.first.want_level
  end

  def test_save_returns_not_found_for_unknown_technology
    patch :save, params: { technology_id: 0,
                           rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_response :not_found
  end

  def test_save_returns_unprocessable_entity_for_unknown_level
    patch :save, params: { technology_id: @t1.id,
                           rating: { can_level: 'wizard', want_level: 'yes' } }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)
  end

  def test_save_returns_unprocessable_entity_for_malformed_rating
    patch :save, params: { technology_id: @t1.id, rating: 'oops' }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)
  end

  def test_index_forbidden_for_user_without_rate_permission
    jsmith = User.find_by(login: 'jsmith')
    @request.session[:user_id] = jsmith.id

    get :index

    assert_response :forbidden
  end

  def test_show_renders_first_unrated_technology
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :show

    assert_response :success
    assert_select 'h2', text: 'Rails'
  end

  def test_show_renders_done_message_when_all_rated
    [@t1, @t2].each do |t|
      TechRadar::Rating.create!(user_id: @admin.id, technology: t,
                                can_level: :unknown, want_level: :neutral)
    end

    get :show

    assert_response :success
    assert_select '.tech-radar-card-done'
  end

  def test_update_persists_rating_and_redirects_to_next_card
    patch :update, params: { rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_rating_path
    rating = TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)

    assert_equal 'advanced', rating.can_level
    assert_equal 'yes', rating.want_level
  end

  def test_update_returns_unprocessable_entity_for_unknown_can_level
    patch :update, params: { rating: { can_level: 'wizard', want_level: 'yes' } }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)
  end

  def test_update_returns_unprocessable_entity_for_unknown_want_level
    patch :update, params: { rating: { can_level: 'advanced', want_level: 'maybe' } }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)
  end

  def test_skip_advances_without_persisting
    post :skip

    assert_redirected_to tech_radar_rating_path
    assert_equal 0, TechRadar::Rating.where(user_id: @admin.id).count
  end

  def test_skip_does_not_advance_past_last_unrated_technology
    TechRadar::Rating.create!(user_id: @admin.id, technology: @t1,
                              can_level: :unknown, want_level: :neutral)

    post :skip

    assert_redirected_to tech_radar_rating_path

    get :show

    assert_select 'h2', text: 'Rails'
    assert_select '.tech-radar-card-done', count: 0
  end

  def test_back_returns_to_previous_card
    patch :update, params: { rating: { can_level: 'beginner', want_level: 'no' } }
    post :back

    assert_redirected_to tech_radar_rating_path
    get :show

    assert_select 'h2', text: 'Ruby'
  end

  def test_show_forbidden_for_user_without_rate_permission
    jsmith = User.find_by(login: 'jsmith')
    @request.session[:user_id] = jsmith.id

    get :show

    assert_response :forbidden
  end
end
