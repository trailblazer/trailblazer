require "test_helper"
require "trailblazer/operation/collection"

class CollectionTest < MiniTest::Spec
  Song = Struct.new(:title, :id) do
    class << self
      attr_accessor :all_records

      def all
        all_records
      end
    end
  end


  class CreateOperation < Trailblazer::Operation
    include CRUD
    model Song
    action :create

    contract do
      property :title
      validates :title, presence: true
    end

    def process(params)
      validate(params[:song]) do |f|
        f.sync
      end
    end
  end

  class FetchCollectionOperation < CreateOperation
    include Trailblazer::Operation::Collection

    model Song

    contract do
      property :title
    end

    def model!(params)
      Song.all
    end
  end

  # ::present.
  it do
    Song.all_records = [
      CreateOperation.(song: {title: "Blue Rondo a la Turk"}).model,
      CreateOperation.(song: {title: "Mercy Day For Mr. Vengeance"}).model
    ]
    op = FetchCollectionOperation.present(user_id: 0)
    op.model.must_equal Song.all_records
  end
end