# frozen_string_literal: true

class CreateUserParties < ActiveRecord::Migration[5.2]
  def change
    create_table :user_parties do |t|
      t.integer :host
      t.references :user, foreign_key: true
      t.references :party, foreign_key: true
    end
  end
end
