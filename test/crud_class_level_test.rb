require "test_helper"
require "trailblazer/operation/crud/class_builder"

class CrudClassLevelTest < MiniTest::Spec
   Song = Struct.new(:title, :id) do
    class << self
      attr_accessor :find_result # TODO: eventually, replace with AR test.
      attr_accessor :all_records

      def find(id)
        find_result
      end
    end
  end # FIXME: use from CrudTest.




  class Bla < Trailblazer::Operation
    include CRUD::ClassBuilder
    model Song

    def process(params)

    end
  end

  it do
    Bla.model!({}).must_equal Song.new
  end

  it "bla" do
    Bla.({}).model.must_equal Song.new
  end
end