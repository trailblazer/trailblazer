require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(operation_class, options={})
    res, options = operation_for!(operation_class, options) { |params| { operation: operation_class.present(params) } }
    res.contract.prepopulate!(options) # equals to @form.prepopulate!

    res.contract
  end

  # Provides the operation instance, model and contract without running #process.
  # Returns the operation.
  def present(operation_class, options={})
    res, options = operation_for!(operation_class, options.merge(skip_form: true)) { |params| { operation: operation_class.present(params) } }
    res # FIXME.
  end

  def collection(*args)
    res, op = operation!(*args)
    @collection = op.model
    op
  end

  def run(operation_class, options={}, &block)
    res = operation_for!(operation_class, options) { |params| operation_class.(params) }

    yield res if res[:valid] and block_given?

    res # FIXME.
  end

  # The block passed to #respond is always run, regardless of the validity result.
  def respond(operation_class, options={}, &block)
    res, op = operation_for!(operation_class, options) { |params| operation_class.run(params) }
    namespace = options.delete(:namespace) || []

    return respond_with *namespace, op, options if not block_given?
    respond_with *namespace, op, options, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

private
  def process_params!(params)
  end

  # Normalizes parameters and invokes the operation (including its builders).
  def operation_for!(operation_class, options, &block)
    params = options[:params] || self.params # TODO: test params: parameter properly in all 4 methods.
    process_params!(params) # deprecate or rename to #setup_params!

    res = Endpoint.new(operation_class, params, request, options).(&block)
    setup_operation_instance_variables!(res, options)

    [res, options.merge(params: params)]
  end

  def setup_operation_instance_variables!(result, options)
    @operation = result # FIXME: remove!
    @model     = result["model"]
    @form      = result["contract"] unless options[:skip_form]
  end

  # Encapsulates HTTP-specific logic needed before running an operation.
  # Right now, all this does is #document_body! which figures out whether or not to pass the request body
  # into params, so the operation can use a representer to deserialize the original document.
  # To be used in Hanami, Roda, Rails, etc.
  class Endpoint
    def initialize(operation_class, params, request, options)
      @operation_class = operation_class
      @params          = params
      @request         = request
      @is_document     = options[:is_document]
    end

    def call
      document_body! if @is_document
      yield @params# Create.run(params)
    end

  private
    attr_reader :params, :operation_class, :request

    def document_body!
      # this is what happens:
      # respond_with Comment::Update::JSON.run(params.merge(comment: request.body.string))
      concept_name = operation_class.model_class.to_s.underscore # this could be renamed to ::concept_class soon.
      request_body = request.body.respond_to?(:string) ? request.body.string : request.body.read

      params.merge!(concept_name => request_body)
    end
  end
end
