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
                  tech_radar_rating_path(@t1, from: 'list'), 'rating[can_level]', 'advanced'
    assert_select "form[action=?] select[name=?] option[selected][value=?]",
                  tech_radar_rating_path(@t1, from: 'list'), 'rating[want_level]', 'yes'
  end

  def test_index_does_not_preselect_another_users_rating
    jsmith = User.find_by(login: 'jsmith')
    TechRadar::Rating.create!(user: jsmith, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_response :success
    assert_select "form[action=?] option[selected]",
                  tech_radar_rating_path(@t1, from: 'list'), count: 0
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
                  tech_radar_rating_path(@t1, from: 'list'), 'rating[can_level]', 'advanced'
    assert_select "form[action=?] option[selected]",
                  tech_radar_rating_path(@t2, from: 'list'), count: 0
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

  def test_update_from_list_creates_rating_and_redirects_to_overview
    patch :update, params: { technology_id: @t1.id, from: 'list',
                             rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_ratings_path
    rating = TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)

    assert_equal 'advanced', rating.can_level
    assert_equal 'yes', rating.want_level
  end

  def test_update_from_list_preserves_the_current_page
    patch :update, params: { technology_id: @t1.id, from: 'list', page: 2,
                             rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_ratings_path(page: 2)
  end

  def test_update_returns_unprocessable_entity_for_malformed_rating
    patch :update, params: { technology_id: @t1.id, rating: 'oops' }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user_id: @admin.id, technology: @t1)
  end

  def test_rate_redirects_to_first_unrated_technology
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :rate

    assert_redirected_to tech_radar_rating_path(@t2)
  end

  def test_rate_renders_done_when_all_rated
    [@t1, @t2].each do |t|
      TechRadar::Rating.create!(user: @admin, technology: t,
                                can_level: :unknown, want_level: :neutral)
    end

    get :rate

    assert_select '.tech-radar-card-done'
  end

  def test_show_renders_previous_highlight_on_rated_levels
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :show, params: { technology_id: @t1.id }

    assert_select ".tech-radar-card-can button.previous[data-level='advanced']"
    assert_select ".tech-radar-card-want button.previous[data-level='yes']"
    assert_select 'button.previous', count: 2
  end

  def test_show_renders_no_previous_highlight_when_unrated
    get :show, params: { technology_id: @t1.id }

    assert_response :success
    assert_select 'button.previous', count: 0
  end

  def test_show_links_next_to_following_card_and_omits_back_on_first
    get :show, params: { technology_id: @t1.id }

    assert_select "a[data-rating-card-target='next'][href=?]",
                  tech_radar_rating_path(@t2)
    assert_select "a[data-rating-card-target='back']", count: 0
  end

  def test_show_links_back_to_previous_card_and_omits_next_on_last
    get :show, params: { technology_id: @t2.id }

    assert_select "a[data-rating-card-target='back'][href=?]",
                  tech_radar_rating_path(@t1)
    assert_select "a[data-rating-card-target='next']", count: 0
  end

  def test_show_returns_not_found_for_unknown_technology
    get :show, params: { technology_id: 0 }

    assert_response :not_found
  end

  def test_update_persists_rating_and_redirects_to_following_card
    patch :update, params: { technology_id: @t1.id,
                             rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_rating_path(@t2)
    rating = TechRadar::Rating.find_by(user: @admin, technology: @t1)

    assert_equal 'advanced', rating.can_level
    assert_equal 'yes', rating.want_level
  end

  def test_update_advances_to_following_card_even_when_it_is_already_rated
    TechRadar::Rating.create!(user: @admin, technology: @t2,
                              can_level: :beginner, want_level: :no)

    patch :update, params: { technology_id: @t1.id,
                             rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_rating_path(@t2)
  end

  def test_update_on_last_card_redirects_to_entry
    patch :update, params: { technology_id: @t2.id,
                             rating: { can_level: 'beginner', want_level: 'no' } }

    assert_redirected_to rate_tech_radar_ratings_path
  end

  def test_update_overwrites_existing_rating_keeping_one_row
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :beginner, want_level: :no)

    patch :update, params: { technology_id: @t1.id,
                             rating: { can_level: 'professional', want_level: 'yes' } }

    ratings = TechRadar::Rating.where(user: @admin, technology: @t1)

    assert_equal 1, ratings.count
    assert_equal 'professional', ratings.first.can_level
    assert_equal 'yes', ratings.first.want_level
  end

  def test_update_returns_unprocessable_entity_for_unknown_can_level
    patch :update, params: { technology_id: @t1.id,
                             rating: { can_level: 'wizard', want_level: 'yes' } }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user: @admin, technology: @t1)
  end

  def test_update_returns_unprocessable_entity_for_unknown_want_level
    patch :update, params: { technology_id: @t1.id,
                             rating: { can_level: 'advanced', want_level: 'maybe' } }

    assert_response :unprocessable_entity
    assert_nil TechRadar::Rating.find_by(user: @admin, technology: @t1)
  end

  def test_update_returns_not_found_for_unknown_technology
    patch :update, params: { technology_id: 0,
                             rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_response :not_found
  end

  def test_index_forbidden_for_user_without_rate_permission
    @request.session[:user_id] = User.find_by(login: 'jsmith').id

    get :index

    assert_response :forbidden
  end

  def test_show_forbidden_for_user_without_rate_permission
    @request.session[:user_id] = User.find_by(login: 'jsmith').id

    get :show, params: { technology_id: @t1.id }

    assert_response :forbidden
  end
end
