# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class RatingTableTest < ActiveSupport::TestCase
    include TechRadarTestHelpers

    fixtures :users

    def setup
      @jsmith = User.find_by(login: 'jsmith')
      @dlopper = User.find_by(login: 'dlopper')
      @rhill = User.find_by(login: 'rhill')
      [@jsmith, @dlopper, @rhill].each { |user| grant_rating_role(user) }
      @ruby = Technology.create!(name: 'Ruby')
      @rails = Technology.create!(name: 'Rails')
    end

    def test_lists_all_ratings_by_technology_then_best_first_then_unrated_raters
      Rating.create!(user: @jsmith,  technology: @ruby,  can_level: :beginner,     want_level: :yes)
      Rating.create!(user: @dlopper, technology: @ruby,  can_level: :professional, want_level: :no)
      Rating.create!(user: @jsmith,  technology: @rails, can_level: :advanced,     want_level: :neutral)

      assert_equal [
        ['John Smith',  'Rails', 'advanced'],
        ['Dave Lopper', 'Ruby',  'professional'],
        ['John Smith',  'Ruby',  'beginner'],
        ['Robert Hill', nil,     nil]
      ], summary(RatingTable.new.rows)
    end

    def test_person_filter_lists_their_ratings_by_can_then_want_without_unrated_raters
      Rating.create!(user: @jsmith, technology: @ruby,  can_level: :advanced, want_level: :neutral)
      Rating.create!(user: @jsmith, technology: @rails, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @dlopper, technology: @ruby, can_level: :professional, want_level: :yes)

      rows = RatingTable.new(user_id: @jsmith.id).rows

      assert_equal [%w[Rails yes], %w[Ruby neutral]], rows.map { |row| [row.technology.name, row.rating.want_level] }
    end

    def test_technology_filter_lists_raters_by_can_then_want_then_who_has_not_rated_it
      Rating.create!(user: @jsmith,  technology: @ruby,  can_level: :advanced, want_level: :neutral)
      Rating.create!(user: @dlopper, technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @rhill,   technology: @rails, can_level: :professional, want_level: :yes)

      assert_equal [
        ['Dave Lopper', 'Ruby', 'advanced'],
        ['John Smith',  'Ruby', 'advanced'],
        ['Robert Hill', 'Ruby', nil]
      ], summary(RatingTable.new(technology_id: @ruby.id).rows)
    end

    def test_orders_equal_ratings_by_name
      Rating.create!(user: @rhill,  technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :advanced, want_level: :yes)

      assert_equal ['John Smith', 'Robert Hill'], RatingTable.new(technology_id: @ruby.id).rows.first(2).map { |row| row.user.name }
    end

    def test_keeps_ratings_of_users_who_are_no_longer_raters
      admin = User.find_by(login: 'admin')
      Rating.create!(user: admin, technology: @ruby, can_level: :advanced, want_level: :yes)

      assert_equal admin, RatingTable.new(technology_id: @ruby.id).rows.first.user
    end

    private

    def summary(rows)
      rows.map { |row| [row.user.name, row.technology&.name, row.rating&.can_level] }
    end
  end
end
