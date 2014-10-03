require 'test_helper'
require 'trailblazer/operation'
require 'reform'

class CrudTest < MiniTest::Spec
  Song = Struct.new(:title)

  class CreateOperation < Trailblazer::Operation
    include CRUD
    model Song
    action :create

    class Contract < Reform::Form
      property :title
      validates :title, presence: true
    end

    def process(params)
      validate(params[:song]) do |f|
        f.sync
      end
    end
  end

  # creates model for you.
  it { CreateOperation[song: {title: "Blue Rondo a la Turk"}].model.title.must_equal "Blue Rondo a la Turk" }
  # exposes #model.
  it { CreateOperation[song: {title: "Blue Rondo a la Turk"}].model.must_be_instance_of Song }

  class ModifyingCreateOperation < CreateOperation
    def process(params)
      model.instance_eval { def genre; "Punkrock"; end }

      validate(params[:song]) do |f|
        f.sync
      end
    end
  end

  # lets you create model.
  it { ModifyingCreateOperation[song: {title: "Blue Rondo a la Turk"}].model.title.must_equal "Blue Rondo a la Turk" }
  it { ModifyingCreateOperation[song: {title: "Blue Rondo a la Turk"}].model.genre.must_equal "Punkrock" }
end