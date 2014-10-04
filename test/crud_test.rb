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

  # lets you modify model.
  it { ModifyingCreateOperation[song: {title: "Blue Rondo a la Turk"}].model.title.must_equal "Blue Rondo a la Turk" }
  it { ModifyingCreateOperation[song: {title: "Blue Rondo a la Turk"}].model.genre.must_equal "Punkrock" }


  class DefaultCreateOperation < Trailblazer::Operation
    include CRUD
    model Song

    def process(params)
      self
    end
  end

  # uses :create as default if not set via ::action.
  it { DefaultCreateOperation[{}].model.must_equal Song.new }

  # no call to ::model raises error.
  class NoModelOperation < Trailblazer::Operation
    include CRUD

    def process(params)
      self
    end
  end

  # uses :create as default if not set via ::action.
  it { assert_raises(RuntimeError){ NoModelOperation[{}] } }
end