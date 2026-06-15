# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class TechnologyTest < ActiveSupport::TestCase
    fixtures :users

    def setup
      @user = User.find_by(login: 'jsmith')
      @t1 = Technology.create!(name: 'Ruby')
      @t2 = Technology.create!(name: 'Rails')
      @t3 = Technology.create!(name: 'Stimulus')
    end

    def test_unrated_by_returns_all_technologies_in_id_order_when_none_rated
      assert_equal [@t1, @t2, @t3], Technology.unrated_by(@user).to_a
    end

    def test_unrated_by_excludes_rated_technologies
      Rating.create!(user: @user, technology: @t2, can_level: :advanced, want_level: :yes)

      assert_equal [@t1, @t3], Technology.unrated_by(@user).to_a
    end

    def test_next_unrated_after_nil_returns_first_unrated
      assert_equal @t1, Technology.next_unrated_after(@user, nil)
    end

    def test_next_unrated_after_returns_next_higher_id
      assert_equal @t2, Technology.next_unrated_after(@user, @t1)
    end

    def test_next_unrated_after_does_not_wrap_when_current_is_highest
      assert_nil Technology.next_unrated_after(@user, @t3)
    end

    def test_next_unrated_after_returns_nil_when_no_higher_unrated_remains
      Rating.create!(user: @user, technology: @t1, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @user, technology: @t3, can_level: :beginner, want_level: :no)

      assert_nil Technology.next_unrated_after(@user, @t2)
    end

    def test_next_unrated_after_returns_nil_when_all_rated
      [@t1, @t2, @t3].each do |t|
        Rating.create!(user: @user, technology: t, can_level: :unknown, want_level: :neutral)
      end

      assert_nil Technology.next_unrated_after(@user, @t1)
    end
  end
end
