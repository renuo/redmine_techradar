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

  def test_back_hidden_on_first_technology
    log_user('admin', 'admin')

    visit '/tech_radar/rate'

    assert_selector 'h2', text: 'Ruby'
    assert_no_button 'Back' # no history yet, so the back button stays hidden
  end

  def test_back_shows_previously_chosen_rating
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_button 'Back'

    assert_selector 'h2', text: 'Ruby'
    assert_equal %w[beginner no], all('button.previous').pluck('data-level').sort
  end

  def test_re_rate_after_back_keeps_one_row_with_new_values
    log_user('admin', 'admin')

    visit '/tech_radar/rate'
    click_button '2. Beginner'
    click_button '1. No'

    assert_selector 'h2', text: 'Rails'
    click_button 'Back'

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

    # Walk back through every rated card, then forward again.
    # Each revisited card must show its saved rating, not just the first one.
    shown = {}
    page.go_back
    shown['Vue back'] = previous_levels('Vue')
    page.go_back
    shown['Rails back'] = previous_levels('Rails')
    page.go_back
    shown['Ruby back'] = previous_levels('Ruby')
    page.go_forward
    shown['Rails forward'] = previous_levels('Rails')
    page.go_forward
    shown['Vue forward'] = previous_levels('Vue')

    assert_equal({
                   'Vue back' => %w[professional yes], 'Rails back' => %w[advanced yes],
                   'Ruby back' => %w[beginner no], 'Rails forward' => %w[advanced yes],
                   'Vue forward' => %w[professional yes]
                 }, shown)
  end

  # Right arrow walks forward through history, not to the next unrated card like Skip.
  def test_forward_key_walks_history_instead_of_skipping
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

  def rating_values_for(technology)
    TechRadar::Rating.where(user: @user, technology: technology)
                     .map { |r| r.slice(:can_level, :want_level).symbolize_keys }
  end
end
