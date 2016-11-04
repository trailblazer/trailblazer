require "test_helper"
require "trailblazer/endpoint"

class EndpointTest < Minitest::Spec
  Song = Struct.new(:id, :title, :length) do
    def self.find_by(id:nil); id.nil? ? nil : "bla" end
  end

  require "representable/json"
  class Serializer < Representable::Decorator
    include Representable::JSON
    property :id
    property :title
    property :length

    class Errors < Representable::Decorator
      include Representable::JSON
      property :messages
    end
  end

  class Deserializer < Representable::Decorator
    include Representable::JSON
    property :title
  end


  class Create < Trailblazer::Operation
    include Policy::Guard
    policy ->(*) { self["user.current"] == ::Module }

    extend Representer::DSL
    representer :serializer, Serializer
    representer :deserializer, Deserializer
    representer :errors, Serializer::Errors
    # self["representer.serializer.class"] = Representer
    # self["representer.deserializer.class"] = Deserializer

    include Model
    model Song, :create

    include Contract::Step
    include Representer::Deserializer::JSON
    contract do
      property :title
      property :length

      include Reform::Form::ActiveModel::Validations
      validates :title, presence: true
    end

    def process(params)
      validate(params) do |f|
        f.sync
        self["model"].id = 9
      end
    end
  end

  let (:controller) { self }

  let (:_data) { [] }

  def head(*args)
    _data << [:head, *args]
  end

  let(:handlers) { Trailblazer::Endpoint::Handlers::Rails.new(self).() }

  # not authenticated, 401
  it do
    result = Create.( { id: 1 }, "user.current" => false )
    # puts "@@@@@ #{result.inspect}"

    Trailblazer::Endpoint.new.(handlers, result)
    _data.inspect.must_equal %{[[:head, 401]]}
  end

  # created
  # length is ignored as it's not defined in the deserializer.
  it do
    result = Create.( '{"id": 9, "title": "Encores", "length": 999 }', "user.current" => ::Module )
    # puts "@@@@@ #{result.inspect}"

    Trailblazer::Endpoint.new.(handlers, result)
    _data.inspect.must_equal '[[:head, 201, "Location: /song/9", "{\"id\":9,\"title\":\"Encores\"}"]]'
  end

  class Update < Create
    action :find_by
  end
  # 404
  it do
    result = Update.( id: nil, song: '{"id": 9, "title": "Encores", "length": 999 }', "user.current" => ::Module )

    Trailblazer::Endpoint.new.(handlers, result)
    _data.inspect.must_equal '[[:head, 404]]'
  end

  #---
  # validation failure 422
  # success
  it do
    result = Create.('{ "title": "" }', "user.current" => ::Module)
    puts "@@@@@ #{result.inspect}"
    Trailblazer::Endpoint.new.(handlers, result)
    _data.inspect.must_equal '[[:head, 422, "{\"messages\":{\"title\":[\"can\'t be blank\"]}}"]]'
  end


  include Trailblazer::Endpoint::Controller
  #---
  # Controller#endpoint
  # custom handler.
  it do
    invoked = nil

    endpoint(Update, { id: nil }) do |res|
      res.not_found { invoked = "my not_found!" }
    end

    invoked.must_equal "my not_found!"
    _data.must_equal [] # no rails code involved.
  end

  # generic handler because user handler doesn't match.
  it do
    invoked = nil

    endpoint(Update, { id: nil }) do |res|
      res.invalid { invoked = "my invalid!" }
    end

    _data.must_equal [[:head, 404]]
    invoked.must_equal nil
  end

  # only generic handler
  it do
    endpoint(Update, { id: nil })
    _data.must_equal [[:head, 404]]
  end
end
