require "test_helper"

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
  end

  class Deserializer < Representable::Decorator
    include Representable::JSON
    property :title
  end

  class Show < Trailblazer::Operation
    include Policy::Guard
    policy ->(*) { self["user.current"] == Module }

    extend Representer::DSL
    representer :serializer, Serializer
    representer :deserializer, Deserializer
    # self["representer.serializer.class"] = Representer
    # self["representer.deserializer.class"] = Deserializer

    include Model
    model Song, :create

    include Contract::Step
    include Representer::Deserializer::JSON
    contract do
      property :title
      property :length
    end

    def process(params)
      validate(params) do |f|
        f.sync
        self["model"].id = 9
      end
    end
  end

  let (:controller) { controller = Class.new do
      def head(*args)
        @data = [:head, args]
      end
      attr_reader :data

      def inspect
        @data.inspect
      end
    end.new }

  def matcher(result)
    Matcher.(result) do |m|
      m.unauthenticated { |result| controller.head 401 }
      m.not_found       { |result| controller.head 404 }
      m.created         { |result| controller.head 201, "Location: /song/#{result["model"].id}", result["representer.serializer.class"].new(result["model"]).to_json }
      m.success         { |result| controller.head 200 }
    end
  end

  # not authenticated, 401
  it do
    result = Show.( { id: 1 }, "user.current" => false )
    # puts "@@@@@ #{result.inspect}"

    matcher(result)
    controller.inspect.must_equal %{[:head, [401]]}
  end

  # created
  # length is ignored as it's not defined in the deserializer.
  it do
    result = Show.( '{"id": 9, "title": "Encores", "length": 999 }', "user.current" => Module )
    # puts "@@@@@ #{result.inspect}"

    matcher(result)
    controller.inspect.must_equal '[:head, [201, "Location: /song/9", "{\"id\":9,\"title\":\"Encores\"}"]]'
  end

  class Update < Show
    action :find_by
  end
  # 404
  it do
    result = Update.( id: nil, song: '{"id": 9, "title": "Encores", "length": 999 }', "user.current" => Module )
    puts "@@@@@ #{result.inspect}"

    matcher(result)
    controller.inspect.must_equal '[:head, [404]]'
  end

end

require "dry/matcher"


# 404
# 422 validation errors
Matcher = Dry::Matcher.new(
    success: Dry::Matcher::Case.new(
      match:   ->(result) { result.success? },
      resolve: ->(result) { result }),
    created: Dry::Matcher::Case.new(
      match:   ->(result) { result.success? && result["model.action"] == :create }, # the "model.action" doesn't mean you need Model.
      resolve: ->(result) { result }),

    not_found: Dry::Matcher::Case.new(
      match:   ->(result) { result.failure? && result["model.result.success?"]==false }, # DISCUSS: do we want that?
      resolve: ->(result) { result }),
    unauthenticated: Dry::Matcher::Case.new(
      match:   ->(result) { result.failure? && result["policy.result"]&& result["policy.result"]["success?"]==false }, # FIXME: we might need a &. here ;)
      resolve: ->(result) { result })
)


    # result = Matcher.(res) do |m|
    #   m.success { |v| asserted = "valid is true" }
