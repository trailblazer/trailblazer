require "test_helper"

class ModelTest < MiniTest::Spec
  Song = Struct.new(:title, :id) do
    class << self
      attr_accessor :find_result # TODO: eventually, replace with AR test.
      attr_accessor :all_records

      def find(id)
        find_result
      end
    end
  end

  class Create < Trailblazer::Operation
    include Contract
    include Setup
    include Model
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

  describe "dependency injection" do
    Hit = Class.new(Song)
    it { Create.({ song: {} }, "model.class" => Hit)["model"].class.must_equal Hit }

    # "model" => Model.new
    class Show < Trailblazer::Operation
      def call(*); self["model"]; end
    end
    it { Show.().must_equal nil }
    it { Show.({}, "model" => String).must_equal String }

    # with Setup
    class Index < Trailblazer::Operation
      include Setup
      def call(*); model; end
    end
    it { Index.().must_equal nil }
    it { skip; Index.({}, "model" => String).must_equal String }
  end

  # creates model for you.
  it { Create.(song: {title: "Blue Rondo a la Turk"})["model"].title.must_equal "Blue Rondo a la Turk" }
  # exposes #model.
  it { Create.(song: {title: "Blue Rondo a la Turk"})["model"].must_be_instance_of Song }

  class ModifyingCreate < Create
    def process(params)
      model.instance_eval { def genre; "Punkrock"; end }

      validate(params[:song]) do |f|
        f.sync
      end
    end
  end

  # lets you modify model.
  it { ModifyingCreate.(song: {title: "Blue Rondo a la Turk"})["model"].title.must_equal "Blue Rondo a la Turk" }
  it { ModifyingCreate.(song: {title: "Blue Rondo a la Turk"})["model"].genre.must_equal "Punkrock" }

  # Update
  class UpdateOperation < Create
    action :update
  end

  # finds model and updates.
  it do
    song = Create.(song: {title: "Anchor End"})["model"]
    Song.find_result = song

    UpdateOperation.(id: song.id, song: {title: "The Rip"})["model"].title.must_equal "The Rip"
    song.title.must_equal "The Rip"
  end

  # Find == Update
  class FindOperation < Create
    action :find
  end

  # finds model and updates.
  it do
    song = Create.(song: {title: "Anchor End"})["model"]
    Song.find_result = song

    FindOperation.(id: song.id, song: {title: "The Rip"})["model"].title.must_equal "The Rip"
    song.title.must_equal "The Rip"
  end


  class DefaultCreate < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract
    require "trailblazer/operation/setup"
    include Setup
    include Model
    model Song

    def process(params)
      self
    end
  end

  # uses :create as default if not set via ::action.
  it { DefaultCreate.({})["model"].must_equal Song.new }

  # model Song, :action
  class ModelUpdateOperation < Create
    model Song, :update
  end

  # allows :"model", :action.
  it do
    Song.find_result = song = Song.new
    ModelUpdateOperation.({id: 1, song: {title: "Mercy Day For Mr. Vengeance"}})["model"].must_equal song
  end



  # Op#setup_model!
  class SetupModelOperation < Create
    def setup_model!(params)
      model.instance_eval { @params = params; def params; @params.to_s; end }
    end
  end

  it { SetupModelOperation.(song: {title: "Emily Kane"})["model"].params.must_equal "{:song=>{:title=>\"Emily Kane\"}}" }



  # no call to :"model" raises error.
  class NoModelOperation < Trailblazer::Operation
    require "trailblazer/operation/contract"
    include Contract
    require "trailblazer/operation/setup"
    include Setup
    include Model

    def process(params)
      model
    end
  end

  # uses :create as default if not set via ::action.
  it { assert_raises(RuntimeError){ NoModelOperation.({}) } }

  # allow passing validate(params, model, contract_class)
  class OperationWithPrivateContract < Trailblazer::Operation
    include Setup
    include Contract
    include Model
    model Song

    class MyContract < Reform::Form
      property :title
    end

    def process(params)
      validate(params[:song], model, {}, MyContract) do |f|
        f.sync
      end
    end
  end

  # uses private Contract class.
  it { OperationWithPrivateContract.(song: {title: "Blue Rondo a la Turk"})["model"].title.must_equal "Blue Rondo a la Turk" }
end
