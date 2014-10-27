# models
class Song < ActiveRecord::Base
end


#migrations
class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table(:songs) {|t| t.string :title; t.integer :length}
  end
end
ActiveRecord::Migration.verbose = false
CreateAllTables.up