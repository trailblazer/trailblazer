require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(operation_class, options={})
    operation!(operation_class, options).tap do |op|
      op.contract.prepopulate!(options) # equals to @form.prepopulate!
    end.contract
  end

  # Provides the operation instance, model and contract without running #process.
  # Returns the operation.
  def present(operation_class, options={})
    operation!(operation_class, options.merge(skip_form: true))
  end

  def collection(*args)
    operation!(*args).tap do |op|
      @collection = op.model
    end
  end

  def run(operation_class, options={}, &block)
    res, op = operation_for!(operation_class, options) { |params| operation_class.run(params) }

    yield op if res and block_given?

    op
  end

  # The block passed to #respond is always run, regardless of the validity result.
  def respond(operation_class, options={}, &block)
    res, op   = operation_for!(operation_class, options) { |params| operation_class.run(params) }
    namespace = options.delete(:namespace) || []

    return respond_with *namespace, op, options if not block_given?
    respond_with *namespace, op, options, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

private
  def operation!(operation_class, options={}) # or #model or #setup.
    res, op = operation_for!(operation_class, options) { |params| [true, operation_class.present(params)] }
    op
  end

  def process_params!(params)
  end

  # Normalizes parameters and invokes the operation (including its builders).
  def operation_for!(operation_class, options, &block)
    params  = options.delete(:params) || self.params # TODO: test params: parameter properly in all 4 methods.

    process_params!(params)
    res, op = Trailblazer::Endpoint.new(operation_class, params, request, options).(&block)
    setup_operation_instance_variables!(op, options)

    [res, op]
  end

  def setup_operation_instance_variables!(operation, options)
    @operation = operation
    @model     = operation.model
    @form      = operation.contract unless options[:skip_form]
  end
end
