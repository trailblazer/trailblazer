require "dry/matcher"

module Trailblazer
  class Endpoint
    # this is totally WIP as we need to find best practices.
    # also, i want this to be easily extendable.
    Matcher = Dry::Matcher.new(
      success: Dry::Matcher::Case.new(
        match:   ->(result) { result.success? },
        resolve: ->(result) { result }),
      created: Dry::Matcher::Case.new(
        match:   ->(result) { result.success? && result["model.action"] == :create }, # the "model.action" doesn't mean you need Model.
        resolve: ->(result) { result }),
      not_found: Dry::Matcher::Case.new(
        match:   ->(result) { result.failure? && result["result.model"] && result["result.model"].failure? },
        resolve: ->(result) { result }),
      # TODO: we could add unauthorized here.
      unauthenticated: Dry::Matcher::Case.new(
        match:   ->(result) { result.failure? && result["result.policy"].failure? }, # FIXME: we might need a &. here ;)
        resolve: ->(result) { result }),
      invalid: Dry::Matcher::Case.new(
        match:   ->(result) { result.failure? && result["result.contract"] },
        resolve: ->(result) { result })
    )

    def self.call(handlers, operation_class, *args, &block)
      result = operation_class.(*args)
      new.(handlers, result, &block)
    end

    def call(handlers, result, &block)
      matcher.(result, &block) and return if block_given? # evaluate user blocks first.
      matcher.(result, &handlers)     # then, generic Rails handlers in controller context.
    end

    def matcher
      Matcher
    end

    module Handlers
      # Generic matcher handlers for a Rails API backend.
      class Rails
        def initialize(controller)
          @controller = controller
        end

        attr_reader :controller

        def call
          ->(m) do
            m.not_found       { |result| controller.head 404 }
            m.unauthenticated { |result| controller.head 401 }
            m.created         { |result| controller.head 201, "Location: /song/#{result["model"].id}", result["representer.serializer.class"].new(result["model"]).to_json }
            m.success         { |result| controller.head 200 }
            m.invalid         { |result| controller.head 422, result["representer.errors.class"].new(result['result.contract'].errors).to_json }
          end
        end
      end
    end


    module Controller
      # endpoint(Create) do |m|
      #   m.not_found { |result| .. }
      # end
      def endpoint(operation_class, *args, &block)
        handlers = Handlers::Rails.new(self).()
        Endpoint.(handlers, operation_class, *args, &block)
      end
    end
  end
end
