class CreateSearch < ActiveRecord::Migration
  def self.up
    create_table :words do |t|
      t.string   :stem, :default => ""
      t.string   :word, :default => ""
      t.string   :provenance, :default => ""
      t.integer  :frequency, :default => 0
    end
    create_table :transits do |t|
      t.integer  :position
      t.integer  :word_id
      t.integer  :note_id
    end
  end
  def self.down
    drop_table   :words
    drop_table   :transits
  end
end

