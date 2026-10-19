# frozen_string_literal: true

require_relative 'tech_radar_system_test_case'

class RatingsOverviewTest < TechRadarSystemTestCase
  def test_setting_both_axes_persists_rating
    log_user('admin', 'admin')

    visit '/tech_radar/ratings'

    within(:xpath, row_xpath('Ruby')) do
      select 'Advanced', from: 'rating[can_level]'
      select 'Yes', from: 'rating[want_level]'
    end

    assert_selector :xpath, "#{row_xpath('Ruby')}[@data-state='saved']"
    assert_equal [{ can_level: 'advanced', want_level: 'yes' }], rating_values_for(@t1)
  end

  def test_changing_one_axis_on_rated_row_updates_value
    TechRadar::Rating.create!(user: @user, technology: @t1,
                              can_level: :beginner, want_level: :no)
    log_user('admin', 'admin')

    visit '/tech_radar/ratings'

    within(:xpath, row_xpath('Ruby')) do
      select 'Professional', from: 'rating[can_level]'
    end

    assert_selector :xpath, "#{row_xpath('Ruby')}[@data-state='saved']"
    assert_equal [{ can_level: 'professional', want_level: 'no' }], rating_values_for(@t1)
  end

  def test_setting_only_one_axis_does_not_submit
    log_user('admin', 'admin')

    visit '/tech_radar/ratings'

    within(:xpath, row_xpath('Ruby')) do
      select 'Advanced', from: 'rating[can_level]'
    end

    assert_selector :xpath, "#{row_xpath('Ruby')}[@data-state='incomplete']"
    assert_empty rating_values_for(@t1)
  end

  def test_saving_keeps_scroll_position
    40.times { |i| TechRadar::Technology.create!(name: "Tech #{i}") }
    log_user('admin', 'admin')

    visit '/tech_radar/ratings'

    within(:xpath, row_xpath('Tech 39')) do
      select 'Advanced', from: 'rating[can_level]'
      select 'Yes', from: 'rating[want_level]'
    end

    assert_selector :xpath, "#{row_xpath('Tech 39')}[@data-state='saved']"
    assert_operator page.evaluate_script('window.scrollY'), :>, 0
  end

  private

  def row_xpath(name)
    "//form[.//span[normalize-space()='#{name}']]"
  end
end
