require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(operation_class, options={})
    res, options = operation_for!(operation_class, options) { |params| { operation: operation_class.build_operation(params) } }
    res[:operation].contract.prepopulate!(options) # equals to @form.prepopulate!

    res[:operation].contract
  end

  # Provides the operation instance, model and contract without running #process.
  # Returns the operation.
  def present(operation_class, options={})
    res, options = operation_for!(operation_class, options.merge(skip_form: true)) { |params| { operation: operation_class.build_operation(params) } }
    res[:operation] # FIXME.
  end

  def collection(*args)
    res, op = operation!(*args)
    @collection = op.model
    op
  end

  def run(operation_class, options={}, &block)
    res = operation_for!(operation_class, options) { |params| operation_class.(params) }

    yield res[:operation] if res[:valid] and block_given?

    res[:operation] # FIXME.
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

  # Override and return arbitrary params object.
  def params!(params)
    params
  end

  # Normalizes parameters and invokes the operation (including its builders).
  def operation_for!(operation_class, options, &block)
    params = options[:params] || self.params # TODO: test params: parameter properly in all 4 methods.
    params = params!(params)
    process_params!(params) # deprecate or rename to #setup_params!

    res = Trailblazer::Endpoint.new(operation_class, params, request, options).(&block)
    setup_operation_instance_variables!(res, options)

    [res, options.merge(params: params)]
  end

  def setup_operation_instance_variables!(result, options)
    @operation = result[:operation] # FIXME: remove!
    @model     = result[:model]
    @form      = result[:contract] unless options[:skip_form]
  end
end
