require 'trailblazer'
require 'minitest/autorun'
require 'active_record'
require 'database_cleaner'

# ActiveRecord Connection
# ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger = false
ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: ":memory:"
)

# Dot not show Active Record Migrations
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :things do |table|
    table.column :title, :string
    table.column :active, :boolean, default: true
  end
  
  create_table(:bands) do |table|
    table.column :name, :string
    table.column :locality, :string
  end
end

module TmpUploads
  extend ActiveSupport::Concern
  fs_dir = File.join(File.dirname(__FILE__), '..', 'tmp', 'uploads')
  FileUtils.mkdir_p(fs_dir) unless File.exist?(fs_dir)

  included do
    let(:tmp_dir) { File.expand_path(fs_dir) }
  end
end

MiniTest::Spec.class_eval do
  include TmpUploads
end

# Database Cleaning
DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end
