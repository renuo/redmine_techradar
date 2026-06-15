# frozen_string_literal: true

require_relative '../test_helper'

class TechRadarRatingsControllerTest < Redmine::ControllerTest
  tests TechRadarRatingsController

  fixtures :users

  def setup
    User.current = nil
    @admin = User.find_by(login: 'admin')
    @request.session[:user_id] = @admin.id
    @t1 = TechRadar::Technology.create!(name: 'Ruby')
    @t2 = TechRadar::Technology.create!(name: 'Rails')
  end

  def test_index_redirects_to_first_unrated_technology
    TechRadar::Rating.create!(user: @admin, technology: @t1,
                              can_level: :advanced, want_level: :yes)

    get :index

    assert_redirected_to tech_radar_rate_technology_path(@t2)
  end

  def test_index_renders_done_when_all_rated
    [@t1, @t2].each do |t|
      TechRadar::Rating.create!(user: @admin, technology: t,
                                can_level: :unknown, want_level: :neutral)
    end

    get :index

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

  def test_show_sets_skip_url_to_next_unrated
    get :show, params: { technology_id: @t1.id }

    assert_select ".tech-radar-card[data-rating-card-skip-url-value=?]",
                  tech_radar_rate_technology_path(@t2)
  end

  def test_show_omits_skip_url_on_last_unrated
    get :show, params: { technology_id: @t2.id }

    assert_select ".tech-radar-card[data-rating-card-skip-url-value]", count: 0
    assert_select "button[data-rating-card-target='back'][hidden]"
  end

  def test_show_returns_not_found_for_unknown_technology
    get :show, params: { technology_id: 0 }

    assert_response :not_found
  end

  def test_update_persists_rating_and_redirects_to_next_unrated
    patch :update, params: { technology_id: @t1.id,
                             rating: { can_level: 'advanced', want_level: 'yes' } }

    assert_redirected_to tech_radar_rate_technology_path(@t2)
    rating = TechRadar::Rating.find_by(user: @admin, technology: @t1)

    assert_equal 'advanced', rating.can_level
    assert_equal 'yes', rating.want_level
  end

  def test_update_on_last_unrated_redirects_to_entry
    patch :update, params: { technology_id: @t2.id,
                             rating: { can_level: 'beginner', want_level: 'no' } }

    assert_redirected_to tech_radar_rating_path
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
