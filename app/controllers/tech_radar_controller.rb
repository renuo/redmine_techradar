# frozen_string_literal: true

class TechRadarController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index
    @centroids = TechRadar::Rating.centroids_by_technology
  end
end
