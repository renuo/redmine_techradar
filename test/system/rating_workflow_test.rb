# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../../test/application_system_test_case'

class RatingWorkflowTest < ApplicationSystemTestCase
  fixtures :users

  def setup
    super
    @user = User.find_by(login: 'admin')
    @t1 = TechRadar::Technology.create!(name: 'Ruby')
    @t2 = TechRadar::Technology.create!(name: 'Rails')
  end

  def teardown
    TechRadar::Rating.delete_all
    TechRadar::Technology.delete_all
    super
  end

  def test_rate_via_click_persists_and_advances
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    click_button '3. Advanced'
    click_button '5. Yes'

    assert_selector 'h2', text: 'Rails'
    assert_equal [{ can_level: 'advanced', want_level: 'yes' }], rating_values_for(@t1)
  end

  def test_rate_via_keyboard_persists_and_advances
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    find('body').send_keys('3', '5')

    assert_selector 'h2', text: 'Rails'
    assert_equal [{ can_level: 'advanced', want_level: 'yes' }], rating_values_for(@t1)
  end

  def test_skip_advances_without_persisting
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    click_button 'Skip'

    assert_selector 'h2', text: 'Rails'
    assert_empty rating_values_for(@t1)
  end

  def test_back_shows_previously_chosen_rating
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_button 'Back'

    assert_selector 'h2', text: 'Ruby'
    assert_equal %w[beginner no], all('button.selected').pluck('data-level').sort
  end

  def test_re_rate_after_back_keeps_one_row_with_new_values
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_button 'Back'

    assert_selector 'h2', text: 'Ruby'
    click_button '4. Professional'
    click_button '5. Yes'

    assert_equal [{ can_level: 'professional', want_level: 'yes' }], rating_values_for(@t1)
  end

  def test_done_view_shown_after_all_technologies_rated
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '3. Advanced'
    click_button '5. Yes'

    assert_selector 'h2', text: 'Rails'
    click_button '3. Advanced'
    click_button '5. Yes'

    assert_selector '.tech-radar-card-done', text: /rated every technology/i
  end

  private

  def rating_values_for(technology)
    TechRadar::Rating.where(user: @user, technology: technology)
                     .map { |r| r.slice(:can_level, :want_level).symbolize_keys }
  end
end
