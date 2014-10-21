require 'test_helper'
require 'trailblazer/operation'

class CrudTest < MiniTest::Spec
  Song = Struct.new(:title, :id) do
    class << self
      attr_accessor :find_result # TODO: eventually, replace with AR test.

      def find(id)
        find_result
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

  # Update
  class UpdateOperation < CreateOperation
    action :update
  end

  # finds model and updates.
  it do
    song = CreateOperation[song: {title: "Anchor End"}].model
    Song.find_result = song

    UpdateOperation[id: song.id, song: {title: "The Rip"}].model.title.must_equal "The Rip"
    song.title.must_equal "The Rip"
  end

  # Find == Update
  class FindOperation < CreateOperation
    action :find
  end

  # finds model and updates.
  it do
    song = CreateOperation[song: {title: "Anchor End"}].model
    Song.find_result = song

    FindOperation[id: song.id, song: {title: "The Rip"}].model.title.must_equal "The Rip"
    song.title.must_equal "The Rip"
  end


  class DefaultCreateOperation < Trailblazer::Operation
    include CRUD
    model Song

    def process(params)
      self
    end
  end

  # uses :create as default if not set via ::action.
  it { DefaultCreateOperation[{}].model.must_equal Song.new }

  # model Song, :action
  class ModelUpdateOperation < CreateOperation
    model Song, :update
  end

  # allows ::model, :action.
  it do
    Song.find_result = song = Song.new
    ModelUpdateOperation[{id: 1, song: {title: "Mercy Day For Mr. Vengeance"}}].model.must_equal song
  end

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