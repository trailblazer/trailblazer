require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(operation_class, options={})
    options[:___dont_deprecate] = 1 # TODO: remove in 1.1.

    operation!(operation_class, options).tap do |op|
      op.contract.prepopulate!(options) # equals to @form.prepopulate!
    end.contract
  end

  # Provides the operation instance, model and contract without running #process.
  # Returns the operation.
  def present(operation_class, options={})
    operation!(operation_class, skip_form: true)
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
    options[:___dont_deprecate] = 1 # TODO: remove in 1.1.

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
    options = deprecate_positional_params_argument!(options) # TODO: remove in 1.1.

    params  = options.delete(:params) || self.params # TODO: test params: parameter properly in all 4 methods.

    process_params!(params)
    res, op = Trailblazer::Endpoint.new(operation_class, params, request, options).(&block)
    setup_operation_instance_variables!(op, options)

    [res, op]
  end

  def deprecate_positional_params_argument!(options) # TODO: remove in 1.1.
    return options if options.has_key?(:skip_form)
    return options if options.has_key?(:is_document)
    return options if options.has_key?(:params)
    return options if options.has_key?(:namespace)
    return options if options.has_key?(:___dont_deprecate)
    return options if options.size == 0

    warn "[Trailblazer] The positional params argument for #run, #present, #form and #respond is deprecated and will be removed in 1.1.
Please provide a custom params via `run Comment::Create, params: {..}` and have a nice day."
    {params: options}
  end

  def setup_operation_instance_variables!(operation, options)
    @operation = operation
    @model     = operation.model
    @form      = operation.contract unless options[:skip_form]
  end
end
