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

  def test_show_renders_first_unrated_technology
    get :show

    assert_response :success
    assert_select 'h2', text: 'Ruby'
  end

  def test_show_renders_nav_with_rate_marked_active
    get :show

    assert_select 'ul.tech-radar-nav li.active a', text: 'Rate'
    assert_select 'ul.tech-radar-nav li:not(.active) a', text: 'Evaluation'
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
