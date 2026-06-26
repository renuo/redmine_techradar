# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../../../test/application_system_test_case'

# Base class for system tests that drive the rating flow with the standard
# two-technology fixture (Ruby, Rails).
class TechRadarSystemTestCase < ApplicationSystemTestCase
  fixtures :users

  def setup
    super
    @user = User.find_by(login: 'admin')
    @t1 = TechRadar::Technology.create!(name: 'Ruby')
    @t2 = TechRadar::Technology.create!(name: 'Rails')
  end

  private

  def rating_values_for(technology)
    TechRadar::Rating.where(user: @user, technology: technology)
                     .map { |r| r.slice(:can_level, :want_level).symbolize_keys }
  end
end
