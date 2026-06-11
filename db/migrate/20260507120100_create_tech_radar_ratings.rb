# frozen_string_literal: true

class CreateTechRadarRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_radar_ratings do |t|
      t.references :user,
                   null: false,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :technology,
                   null: false,
                   foreign_key: { to_table: :tech_radar_technologies }
      t.integer :can_level, null: false
      t.integer :want_level, null: false
      t.timestamps
    end
    add_index :tech_radar_ratings, %i[user_id technology_id], unique: true
  end
end
