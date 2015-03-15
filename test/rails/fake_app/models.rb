# models
class Song < ActiveRecord::Base
end

class Band < ActiveRecord::Base
  has_many :songs
end

class Tenant < ActiveRecord::Base
  self.table_name = 'public.tenants'
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

    create_table(:"public.tenants") do |t|
      t.string :name
    end
  end
end
ActiveRecord::Migration.verbose = false
CreateAllTables.up

