# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class RatingTableTest < ActiveSupport::TestCase
    fixtures :users

    def setup
      @jsmith = User.find_by(login: 'jsmith')
      @dlopper = User.find_by(login: 'dlopper')
      @rhill = User.find_by(login: 'rhill')
      @ruby = Technology.create!(name: 'Ruby')
      @rails = Technology.create!(name: 'Rails')
    end

    def test_lists_all_ratings_by_technology_then_best_first
      Rating.create!(user: @jsmith,  technology: @ruby,  can_level: :beginner,     want_level: :yes)
      Rating.create!(user: @dlopper, technology: @ruby,  can_level: :professional, want_level: :no)
      Rating.create!(user: @jsmith,  technology: @rails, can_level: :advanced,     want_level: :neutral)

      assert_equal [
        ['John Smith',  'Rails', 'advanced'],
        ['Dave Lopper', 'Ruby',  'professional'],
        ['John Smith',  'Ruby',  'beginner']
      ], summary(RatingTable.new.ratings)
    end

    def test_pages_through_ratings
      Rating.create!(user: @jsmith,  technology: @ruby,  can_level: :beginner,     want_level: :yes)
      Rating.create!(user: @dlopper, technology: @ruby,  can_level: :professional, want_level: :no)
      Rating.create!(user: @jsmith,  technology: @rails, can_level: :advanced,     want_level: :neutral)
      table = RatingTable.new

      assert_equal 3, table.count
      assert_equal [['John Smith', 'Ruby', 'beginner']], summary(table.ratings(offset: 2, limit: 2))
    end

    def test_person_filter_lists_their_ratings_by_can_then_want
      Rating.create!(user: @jsmith, technology: @ruby,  can_level: :advanced, want_level: :neutral)
      Rating.create!(user: @jsmith, technology: @rails, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @dlopper, technology: @ruby, can_level: :professional, want_level: :yes)

      ratings = RatingTable.new(user_id: @jsmith.id).ratings

      assert_equal [%w[Rails yes], %w[Ruby neutral]], ratings.map { |rating| [rating.technology.name, rating.want_level] }
    end

    def test_technology_filter_lists_raters_by_can_then_want
      Rating.create!(user: @jsmith,  technology: @ruby,  can_level: :advanced, want_level: :neutral)
      Rating.create!(user: @dlopper, technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @rhill,   technology: @rails, can_level: :professional, want_level: :yes)

      assert_equal [
        ['Dave Lopper', 'Ruby', 'advanced'],
        ['John Smith',  'Ruby', 'advanced']
      ], summary(RatingTable.new(technology_id: @ruby.id).ratings)
    end

    def test_orders_equal_ratings_by_name
      Rating.create!(user: @rhill,  technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :advanced, want_level: :yes)

      assert_equal ['John Smith', 'Robert Hill'], RatingTable.new(technology_id: @ruby.id).ratings.map { |rating| rating.user.name }
    end

    private

    def summary(ratings)
      ratings.map { |rating| [rating.user.name, rating.technology.name, rating.can_level] }
    end
  end
end
