require "test_helper"
require "representable/json"

class RepresenterTest < MiniTest::Spec
  Album  = Struct.new(:title, :artist)
  Artist = Struct.new(:name)

  class Create < Trailblazer::Operation
    include Contract::Explicit
    include Representer
    include Representer::InferFromContract
    attr_reader :model # FIXME: all we want is #model.

    contract do
      property :title
      validates :title, presence: true
      property :artist, populate_if_empty: Artist do
        property :name
        validates :name, presence: true
      end
    end

    def call(params)
      self["model"] = Album.new # NO artist!!!
      validate(params[:album], model: self["model"])
      self
    end
  end


  # Infers representer from contract, no customization.
  class Show < Create
    def call(params)
      self["model"] = Album.new("After The War", Artist.new("Gary Moore"))
      self
    end
  end


  # Infers representer, adds hypermedia.
  require "roar/json/hal"
  class HypermediaCreate < Create
    representer do
      include Roar::JSON::HAL

      link(:self) { "//album/#{represented.title}" }
    end
  end

  class HypermediaShow < HypermediaCreate
    def call(params)
      self["model"] = Album.new("After The War", Artist.new("Gary Moore"))
      self
    end
  end


  # rendering
  # generic contract -> representer
  it { Show.().to_json.must_equal %{{"title":"After The War","artist":{"name":"Gary Moore"}}} }

  # contract -> representer with hypermedia
  it do
    HypermediaShow.().to_json.must_equal %{{"title":"After The War","artist":{"name":"Gary Moore"},"_links":{"self":{"href":"//album/After The War"}}}}
  end


  # parsing
  it do
    op = Create.(album: %{{"title":"Run For Cover","artist":{"name":"Gary Moore"}}})
    op.contract.title.must_equal "Run For Cover"
    op.contract.artist.name.must_equal "Gary Moore"
  end

  it do
    op = HypermediaCreate.(album: %{{"title":"After The War","artist":{"name":"Gary Moore"},"_links":{"self":{"href":"//album/After The War"}}}})
    op.contract.title.must_equal "After The War"
    op.contract.artist.name.must_equal "Gary Moore"
  end





  # explicit representer set with ::representer_class=.
  require "roar/decorator"
  class JsonApiCreate < Trailblazer::Operation
    include Contract::Explicit
    include Representer
    attr_reader :model

    contract do # we still need contract as the representer writes to the contract twin.
      property :title
    end

    class AlbumRepresenter < Roar::Decorator
      include Roar::JSON
      property :title
    end

    # FIXME: this won't inherit, of course.
    # self["representer.class"] = AlbumRepresenter
    representer AlbumRepresenter

    def call(params)
      self["model"] = Album.new # NO artist!!!
      validate(params[:album], model: self["model"])
      self
    end
  end

  class JsonApiShow < JsonApiCreate
    def call(params)
      self["model"] = Album.new("After The War", Artist.new("Gary Moore"))
      self
    end
  end

  # render.
  it do
    JsonApiShow.().to_json.must_equal %{{"title":"After The War"}}
  end

  # parse.
  it do
    JsonApiCreate.(album: %{{"title":"Run For Cover"}}).contract.title.must_equal "Run For Cover"
  end
end

class InternalRepresenterAPITest < MiniTest::Spec
  Song = Struct.new(:id)

  describe "#represented" do
    class Show < Trailblazer::Operation
      include Contract::Explicit
      include Representer, Model
      model Song, :create

      representer do
        property :class
      end

      def call(*)
        self
      end

      def model # FIXME.
        self["model"]
      end
    end

    it "uses #model as represented, per default" do
      Show.({}).to_json.must_equal '{"class":"InternalRepresenterAPITest::Song"}'
    end

    class ShowContract < Show
      def represented
        "Object"
      end
    end

    it "can be overriden to use the contract" do
      ShowContract.({}).to_json.must_equal %{{"class":"String"}}
    end
  end

  describe "#to_json" do
    class OptionsShow < Trailblazer::Operation
      include Representer

      representer do
        property :class
        property :id
      end

      def to_json(*)
        super(self["params"])
      end

      include Model::Builder
      def model!(*)
        Song.new(1)
      end
    end

    it "allows to pass options to #to_json" do
      OptionsShow.(include: [:id]).to_json.must_equal %{{"id":1}}
    end
  end
end

class DifferentParseAndRenderingRepresenterTest < MiniTest::Spec
  Album = Struct.new(:title)

  # rendering
  class Create < Trailblazer::Operation
    include Contract::Explicit
    extend Representer::DSL
    include Representer::Rendering # no Deserializer::Hash here or anything.

    contract do
      property :title
    end

    representer do
      property :title, as: :Title
    end

    def call(params)
      self["model"] = Album.new
      validate(params) do
        contract.sync
      end
      self
    end
  end

  it do
    Create.(title: "The Kids").to_json.must_equal %{{"Title":"The Kids"}}
  end

  # parsing
  class Update < Trailblazer::Operation
    include Contract::Explicit
    extend Representer::DSL
    include Representer::Deserializer::Hash # no Rendering.

    representer do
      property :title, as: :Title
    end

    contract do
      property :title
    end

    def call(params)
      self["model"] = Album.new

      validate(params) do
        contract.sync
      end

      self
    end

    def to_json(*)
      %{{"title": "#{self["model"].title}"}}
    end
  end

  it do
    Update.("Title" => "The Kids").to_json.must_equal %{{"title": "The Kids"}}
  end
end
