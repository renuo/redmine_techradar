# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class RatingTest < ActiveSupport::TestCase
    fixtures :users

    def setup
      @user1 = User.find(1)
      @user2 = User.find(2)
      @ruby = Technology.create!(name: 'Ruby')
      @rails = Technology.create!(name: 'Rails')
    end

    def teardown
      Rating.delete_all
      Technology.delete_all
    end

    def test_centroids_by_technology_returns_empty_without_ratings
      assert_empty Rating.centroids_by_technology
    end

    def test_centroids_by_technology_uses_single_rating_as_its_own_centroid
      Rating.create!(user: @user1, technology: @ruby, can_level: :advanced, want_level: :yes)

      centroids = Rating.centroids_by_technology

      assert_equal 1, centroids.length
      centroid = centroids.first
      assert_equal @ruby.id, centroid[:id]
      assert_equal 'Ruby', centroid[:name]
      assert_equal 3.0, centroid[:can]
      assert_equal 5.0, centroid[:want]
    end

    def test_centroids_by_technology_averages_multiple_ratings_per_technology
      Rating.create!(user: @user1, technology: @ruby, can_level: :advanced, want_level: :yes)
      Rating.create!(user: @user2, technology: @ruby, can_level: :professional, want_level: :probably_yes)

      centroid = Rating.centroids_by_technology.find { |c| c[:id] == @ruby.id }

      assert_equal 3.5, centroid[:can]
      assert_equal 4.5, centroid[:want]
    end

    def test_centroids_by_technology_returns_one_entry_per_rated_technology
      Rating.create!(user: @user1, technology: @ruby, can_level: :beginner, want_level: :neutral)
      Rating.create!(user: @user1, technology: @rails, can_level: :professional, want_level: :yes)

      centroids = Rating.centroids_by_technology

      assert_equal 2, centroids.length
      assert_equal %w[Rails Ruby], centroids.map { |c| c[:name] }.sort
    end
  end
end
