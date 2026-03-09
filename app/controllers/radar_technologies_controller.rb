class RadarTechnologiesController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index

  end
end
