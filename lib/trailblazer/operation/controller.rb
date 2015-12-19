require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(operation_class, options={})
    res, op, options = operation!(operation_class, options)
    op.contract.prepopulate!(options) # equals to @form.prepopulate!

    op.contract
  end

  # Provides the operation instance, model and contract without running #process.
  # Returns the operation.
  def present(operation_class, options={})
    res, op = operation!(operation_class, options.merge(skip_form: true))
    op
  end

  def collection(*args)
    res, op = operation!(*args)
    @collection = op.model
    op
  end

  def run(operation_class, options={}, &block)
    res, op = operation_for!(operation_class, options) { |params| operation_class.run(params) }

    yield op if res and block_given?

    op
  end

  # The block passed to #respond is always run, regardless of the validity result.
  def respond(operation_class, options={}, &block)
    res, op = operation_for!(operation_class, options) { |params| operation_class.run(params) }
    namespace = options.delete(:namespace) || []

    return respond_with *namespace, op, options if not block_given?
    respond_with *namespace, op, options, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

private
  def operation!(operation_class, options={}) # or #model or #setup.
    operation_for!(operation_class, options) { |params| [true, operation_class.present(params)] }
  end

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

    res, op = Trailblazer::Endpoint.new(operation_class, params, request, options).(&block)
    setup_operation_instance_variables!(op, options)

    [res, op, options.merge(params: params)]
  end

  def setup_operation_instance_variables!(operation, options)
    @operation = operation
    @model     = operation.model
    @form      = operation.contract unless options[:skip_form]
  end
end
