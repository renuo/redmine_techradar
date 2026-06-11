# frozen_string_literal: true

class CreateTechRadarTechnologies < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_radar_technologies do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :tech_radar_technologies, :name, unique: true
  end
end
