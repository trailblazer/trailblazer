require "test_helper"

class EndpointTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  require "representable/json"
  class Representer < Representable::Decorator
    include Representable::JSON
    property :id
    property :title
  end

  class Show < Trailblazer::Operation
    include Policy::Guard
    policy ->(*) { self["user.current"] == Module }

    self["representer.default.serialize"] = Representer

    include Model
    model Song, :create

    def process(params)
      self["model"].id = 9
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
      m.created         { |result| controller.head 201, "Location: /song/#{result["model"].id}", result["representer.default.serialize"].new(result["model"]).to_json }
      m.success         { |result| controller.head 201 }
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
  it do
    result = Show.( { id: 1 }, "user.current" => Module )
    # puts "@@@@@ #{result.inspect}"

    matcher(result)
    controller.inspect.must_equal '[:head, [201, "Location: /song/9", "{\"id\":9}"]]'
  end
end

require "dry/matcher"


Matcher = Dry::Matcher.new(
    success: Dry::Matcher::Case.new(
      match:   ->(result) { result.success? },
      resolve: ->(result) { result }),
    created: Dry::Matcher::Case.new(
      match:   ->(result) { result.success? && result["model.action"] == :create }, # the "model.action" doesn't mean you need Model.
      resolve: ->(result) { result }),

    unauthenticated: Dry::Matcher::Case.new(
      match:   ->(result) { result.failure? && result["policy.result"]["success?"]==false }, # FIXME: we might need a &. here ;)
      resolve: ->(result) { result }

  )
)


    # result = Matcher.(res) do |m|
    #   m.success { |v| asserted = "valid is true" }
