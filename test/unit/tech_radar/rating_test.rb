# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class RatingTest < ActiveSupport::TestCase
    include TechRadarTestHelpers

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

      assert_equal [{ name: 'Ruby', can: 0.5, want: 2.0 }], Rating.centroids_by_technology
    end

    def test_centroids_by_technology_averages_multiple_ratings_per_technology
      Rating.create!(user: @admin, technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :professional, want_level: :probably_yes)

      assert_equal [{ name: 'Ruby', can: 1.0, want: 1.5 }], Rating.centroids_by_technology
    end

    def test_centroids_by_technology_returns_one_entry_per_rated_technology
      Rating.create!(user: @admin, technology: @ruby, can_level: :beginner, want_level: :neutral)
      Rating.create!(user: @admin, technology: @rails, can_level: :professional, want_level: :yes)

      assert_equal %w[Rails Ruby], Rating.centroids_by_technology.pluck(:name).sort
    end

    def test_points_place_can_levels_at_equal_steps
      users = User.where(login: %w[admin jsmith dlopper rhill]).order(:login).to_a
      users.zip(Rating.can_levels.keys).each do |user, level|
        Rating.create!(user: user, technology: @ruby, can_level: level, want_level: :neutral)
      end

      assert_equal [-1.5, -0.5, 0.5, 1.5], Rating.points_for_technology(@ruby.id).pluck(:can).sort
    end

    def test_points_for_user_returns_empty_when_user_has_no_ratings
      assert_empty Rating.points_for_user(@admin.id)
    end

    def test_points_for_user_returns_one_point_per_rated_technology
      Rating.create!(user: @admin, technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin, technology: @rails, can_level: :professional, want_level: :probably_yes)

      points = Rating.points_for_user(@admin.id).sort_by { |p| p[:name] }

      assert_equal [
        { name: 'Rails', can: 1.5, want: 1.0 },
        { name: 'Ruby',  can: 0.5, want: 2.0 }
      ], points
    end

    def test_points_for_user_excludes_other_users_ratings
      Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :beginner, want_level: :neutral)

      assert_equal [{ name: 'Ruby', can: 0.5, want: 2.0 }], Rating.points_for_user(@admin.id)
    end

    def test_points_for_technology_returns_empty_when_technology_has_no_ratings
      assert_empty Rating.points_for_technology(@ruby.id)
    end

    def test_points_for_technology_returns_one_point_per_rater_labelled_by_name
      Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced,     want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :professional, want_level: :probably_yes)

      points = Rating.points_for_technology(@ruby.id).sort_by { |p| p[:name] }

      assert_equal [
        { name: 'John Smith',    can: 1.5, want: 1.0 },
        { name: 'Redmine Admin', can: 0.5, want: 2.0 }
      ], points
    end

    def test_points_for_technology_excludes_ratings_of_other_technologies
      Rating.create!(user: @admin, technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin, technology: @rails, can_level: :beginner, want_level: :neutral)

      assert_equal [{ name: 'Redmine Admin', can: 0.5, want: 2.0 }], Rating.points_for_technology(@ruby.id)
    end

    def test_users_with_ratings_returns_empty_without_ratings
      assert_empty Rating.users_with_ratings
    end

    def test_users_with_ratings_returns_each_rated_user_once
      Rating.create!(user: @admin,  technology: @ruby,  can_level: :advanced, want_level: :yes)
      Rating.create!(user: @admin,  technology: @rails, can_level: :beginner, want_level: :neutral)
      Rating.create!(user: @jsmith, technology: @ruby,  can_level: :beginner, want_level: :neutral)

      assert_equal %w[admin jsmith], Rating.users_with_ratings.map(&:login).sort
    end

    def test_users_with_ratings_orders_by_name
      Rating.create!(user: @admin,  technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @jsmith, technology: @ruby, can_level: :beginner, want_level: :neutral)

      assert_equal ['John Smith', 'Redmine Admin'], Rating.users_with_ratings.map(&:name)
    end

    def test_raters_are_members_with_a_rating_role
      grant_rating_role(@jsmith)

      assert_equal [@jsmith], Rating.raters.to_a
    end

    def test_raters_include_members_of_a_group_with_a_rating_role
      group = Group.create!(lastname: 'Developers')
      group.users << @jsmith
      grant_rating_role(group)

      assert_equal [@jsmith], Rating.raters.to_a
    end

    def test_raters_exclude_admins_without_a_rating_role
      assert_not_includes Rating.raters, @admin
    end

    def test_raters_exclude_locked_users
      grant_rating_role(@jsmith)
      @jsmith.lock!

      assert_empty Rating.raters
    end

    def test_raters_are_all_active_users_when_non_members_may_rate
      Role.non_member.add_permission!(:rate_technologies)

      assert_includes Rating.raters, @jsmith
      assert_includes Rating.raters, @admin
      assert_not_includes Rating.raters, User.find_by(login: 'dlopper2')
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
