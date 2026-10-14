# frozen_string_literal: true

module TechRadar
  class TechnologiesController < ApplicationController
    before_action :require_login
    before_action :authorize_global
    before_action :set_technology, only: [:edit, :update, :destroy]

    def index
      @technology_pages, @technologies = paginate(TechRadar::Technology.order(:name))
      @rating_counts = TechRadar::Rating.where(technology: @technologies).group(:technology_id).count
    end

    def new
      @technology = TechRadar::Technology.new
    end

    def create
      @technology = TechRadar::Technology.new(technology_params)
      if @technology.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to tech_radar_technologies_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @technology.update(technology_params)
        flash[:notice] = l(:notice_successful_update)
        redirect_to tech_radar_technologies_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @technology.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to tech_radar_technologies_path
    end

    private

    def technology_params
      params.expect(tech_radar_technology: [:name])
    end

    def set_technology
      @technology = TechRadar::Technology.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
