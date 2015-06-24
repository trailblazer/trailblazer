module Trailblazer
  # To be used in Lotus, Roda, Rails, etc.
  class Endpoint
    def initialize(controller, operation_class, params, request, config)
      @controller = controller
      @operation_class = operation_class
      @params  = params
      @request = request
      @config  = config
    end

    def call
      @controller.send(:process_params!, params) # FIXME.

      document_body! if document_request?

      res, operation = yield # Create.run(params)
      @controller.send(:setup_operation_instance_variables!, operation)

      [res, operation] # DISCUSS: do we need result here? or can we just go pick op.valid?
    end

  private
    attr_reader :params, :operation_class, :request, :controller

    def document_request?
      # request.format == :html
      @config[:document_formats][request.format.to_sym]
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