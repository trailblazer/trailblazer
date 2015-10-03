module Trailblazer
  # Encapsulates HTTP-specific logic needed before running an operation.
  # Right now, all this does is #document_body! which figures out whether or not to pass the request body
  # into params, so the operation can use a representer to deserialize the original document.
  # To be used in Lotus, Roda, Rails, etc.
  class Endpoint
    def initialize(operation_class, params, request, options)
      @operation_class = operation_class
      @params          = params
      @request         = request
      @is_document     = document_request_for?(options)
    end

    def call
      document_body! if @is_document
      yield @params# Create.run(params)
    end

  private
    attr_reader :params, :operation_class, :request

    # this is a really weak test but will make sure the document_body behavior is only enabled
    # for people who know what they're doing. also, this won't work if you use a polymorphic dispatch,
    # e.g. `run Comment::Create` where the builder will instantiate Create::JSON which has Representer
    # included.
    def document_request_for?(options)
      return options[:is_document] if options.has_key?(:is_document)

      operation_class < Operation::Representer # TODO: this doesn't work with polymorphic dispatch.
    end

    def document_body!
      # this is what happens:
      # respond_with Comment::Update::JSON.run(params.merge(comment: request.body.string))
      concept_name = operation_class.model_class.to_s.underscore # this could be renamed to ::concept_class soon.
      request_body = request.body.respond_to?(:string) ? request.body.string : request.body.read

      params.merge!(concept_name => request_body)
    end
  end
end