# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class RatingTest < ActiveSupport::TestCase
    fixtures :users

    def setup
      @admin = User.find_by(login: 'admin')
      @jsmith = User.find_by(login: 'jsmith')
      @ruby = Technology.create!(name: 'Ruby')
      @rails = Technology.create!(name: 'Rails')
    end

    def test_centroids_by_technology_returns_empty_without_ratings
      assert_empty Rating.centroids_by_technology
    end

    def test_centroids_by_technology_uses_single_rating_as_its_own_centroid
      Rating.create!(user: @admin, technology: @ruby, can_level: :advanced, want_level: :yes)

      assert_equal [{ name: 'Ruby', can: 3.0, want: 5.0 }], Rating.centroids_by_technology
    end

    def test_centroids_by_technology_averages_multiple_ratings_per_technology
      Rating.create!(user: @admin, technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :professional, want_level: :probably_yes)

      assert_equal [{ name: 'Ruby', can: 3.5, want: 4.5 }], Rating.centroids_by_technology
    end

    def test_centroids_by_technology_returns_one_entry_per_rated_technology
      Rating.create!(user: @admin, technology: @ruby, can_level: :beginner, want_level: :neutral)
      Rating.create!(user: @admin, technology: @rails, can_level: :professional, want_level: :yes)

      assert_equal %w[Rails Ruby], Rating.centroids_by_technology.pluck(:name).sort
    end

    def test_points_for_user_returns_empty_when_user_has_no_ratings
      assert_empty Rating.points_for_user(@admin.id)
    end

    def test_points_for_user_returns_one_point_per_rated_technology
      Rating.create!(user: @admin, technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin, technology: @rails, can_level: :professional, want_level: :probably_yes)

      points = Rating.points_for_user(@admin.id).sort_by { |p| p[:name] }

      assert_equal [
        { name: 'Rails', can: 4.0, want: 4.0 },
        { name: 'Ruby',  can: 3.0, want: 5.0 }
      ], points
    end

    def test_points_for_user_excludes_other_users_ratings
      Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :beginner, want_level: :neutral)

      assert_equal [{ name: 'Ruby', can: 3.0, want: 5.0 }], Rating.points_for_user(@admin.id)
    end

    def test_points_for_technology_returns_empty_when_technology_has_no_ratings
      assert_empty Rating.points_for_technology(@ruby.id)
    end

    def test_points_for_technology_returns_one_point_per_rater_labelled_by_login
      Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced,     want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :professional, want_level: :probably_yes)

      points = Rating.points_for_technology(@ruby.id).sort_by { |p| p[:name] }

      assert_equal [
        { name: 'admin',  can: 3.0, want: 5.0 },
        { name: 'jsmith', can: 4.0, want: 4.0 }
      ], points
    end

    def test_points_for_technology_excludes_ratings_of_other_technologies
      Rating.create!(user: @admin, technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin, technology: @rails, can_level: :beginner, want_level: :neutral)

      assert_equal [{ name: 'admin', can: 3.0, want: 5.0 }], Rating.points_for_technology(@ruby.id)
    end

    def test_users_with_ratings_returns_empty_without_ratings
      assert_empty Rating.users_with_ratings
    end

    def test_users_with_ratings_returns_each_rated_user_once
      Rating.create!(user: @admin,  technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin,  technology: @rails, can_level: :beginner, want_level: :neutral)
      Rating.create!(user: @jsmith, technology: @ruby,  can_level: :beginner, want_level: :neutral)

      assert_equal %w[admin jsmith], Rating.users_with_ratings.map(&:login)
    end

    def test_users_with_ratings_orders_by_login
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :beginner, want_level: :neutral)
      Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced, want_level: :yes)

      assert_equal %w[admin jsmith], Rating.users_with_ratings.map(&:login)
    end

    def test_technologies_with_ratings_returns_empty_without_ratings
      assert_empty Rating.technologies_with_ratings
    end

    def test_technologies_with_ratings_returns_each_rated_technology_once
      Rating.create!(user: @admin,  technology: @ruby,  can_level: :advanced,     want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby,  can_level: :professional, want_level: :probably_yes)
      Rating.create!(user: @admin,  technology: @rails, can_level: :beginner,     want_level: :neutral)

      assert_equal %w[Rails Ruby], Rating.technologies_with_ratings.map(&:name)
    end

    def test_technologies_with_ratings_orders_by_name
      Rating.create!(user: @admin, technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin, technology: @rails, can_level: :beginner, want_level: :neutral)

      assert_equal %w[Rails Ruby], Rating.technologies_with_ratings.map(&:name)
    end
  end
end
