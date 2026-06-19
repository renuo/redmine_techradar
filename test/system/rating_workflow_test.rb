# frozen_string_literal: true

require_relative 'tech_radar_system_test_case'

class RatingWorkflowTest < TechRadarSystemTestCase
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

  def test_next_advances_without_persisting
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    click_link 'Next'

    assert_selector 'h2', text: 'Rails'
    assert_empty rating_values_for(@t1)
  end

  def test_back_absent_on_first_technology
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    assert_no_link 'Back' # first technology, nothing comes before it
  end

  def test_back_shows_previously_chosen_rating
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_link 'Back'

    assert_selector 'h2', text: 'Ruby'
    assert_equal %w[beginner no], all('button.previous').pluck('data-level').sort
  end

  def test_re_rate_after_back_keeps_one_row_with_new_values
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_link 'Back'

    find('h2', text: 'Ruby')

    assert_selector 'button.previous', count: 2
    click_button '4. Professional'
    click_button '5. Yes'
    find('h2', text: 'Rails')

    assert_equal [{ can_level: 'professional', want_level: 'yes' }], rating_values_for(@t1)
  end

  def test_back_through_every_rated_card_shows_its_rating
    @t3 = TechRadar::Technology.create!(name: 'Vue')
    @t4 = TechRadar::Technology.create!(name: 'Go')
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    find('h2', text: 'Ruby')
    click_button '2. Beginner'
    click_button '1. No'

    find('h2', text: 'Rails')
    click_button '3. Advanced'
    click_button '5. Yes'

    find('h2', text: 'Vue')
    click_button '4. Professional'
    click_button '5. Yes'

    find('h2', text: 'Go')

    shown = {}
    click_link 'Back'
    shown['Vue'] = previous_levels('Vue')
    click_link 'Back'
    shown['Rails'] = previous_levels('Rails')
    click_link 'Back'
    shown['Ruby'] = previous_levels('Ruby')

    assert_equal({
                   'Vue' => %w[professional yes], 'Rails' => %w[advanced yes],
                   'Ruby' => %w[beginner no]
                 }, shown)
  end

  def test_arrow_keys_navigate_back_and_next
    @t3 = TechRadar::Technology.create!(name: 'Vue')
    @t4 = TechRadar::Technology.create!(name: 'Go')
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    find('h2', text: 'Ruby')
    find('body').send_keys('2', '1')

    find('h2', text: 'Rails')
    find('body').send_keys('3', '5')

    find('h2', text: 'Vue')
    find('body').send_keys('4', '5')

    find('h2', text: 'Go')

    find('body').send_keys(:arrow_left)
    find('h2', text: 'Vue')
    find('body').send_keys(:arrow_left)
    find('h2', text: 'Rails')
    find('body').send_keys(:arrow_left)
    find('h2', text: 'Ruby')

    find('body').send_keys(:arrow_right)

    assert_selector 'h2', text: 'Rails'
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

  # The saved rating highlight for the card currently shown
  def previous_levels(technology_name)
    find('h2', text: technology_name)
    all('button.previous').pluck('data-level').sort
  end
end
