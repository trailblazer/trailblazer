# models
class Song < ActiveRecord::Base
end

class Band < ActiveRecord::Base
  has_many :songs
end

# migrations
class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table(:songs) do |t|
      t.string :title
      t.integer :length
      t.integer :band_id
    end

    create_table(:bands) do |t|
      t.string :name
      t.string :locality
    end
  end
end
ActiveRecord::Migration.verbose = false
CreateAllTables.up