# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../../test/application_system_test_case'

class RatingWorkflowTest < ApplicationSystemTestCase
  fixtures :users

  def setup
    super
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
    assert_equal({ can_level: 'advanced', want_level: 'yes' }, ruby_rating_values)
  end

  def test_skip_advances_without_persisting
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    click_button 'Skip'

    assert_selector 'h2', text: 'Rails'
    assert_nil TechRadar::Rating.find_by(user_id: 1, technology: @t1)
  end

  def test_back_then_re_rate_keeps_one_row_with_new_values
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_button 'Back'

    assert_selector 'h2', text: 'Ruby'
    assert_selector 'button.selected[data-level="beginner"]'
	assert_selector 'button.selected[data-level="no"]'
    click_button '4. Professional'
    click_button '5. Yes'

    expected = [{ can_level: 'professional', want_level: 'yes' }]
    actual = TechRadar::Rating.where(user_id: 1, technology: @t1)
                              .map { |r| r.slice(:can_level, :want_level).symbolize_keys }

    assert_equal expected, actual
  end

  private

  def ruby_rating_values
    rating = TechRadar::Rating.find_by(user_id: 1, technology: @t1)
    rating&.slice(:can_level, :want_level)&.symbolize_keys
  end
end
