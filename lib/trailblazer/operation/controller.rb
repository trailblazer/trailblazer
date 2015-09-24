require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(*args)
    present(*args).tap do |op|
      op.contract.prepopulate! # equals to @form.prepopulate!
    end
  end

  # Provides the operation instance, model and contract without running #process.
  # Returns the operation.
  def present(operation_class, params=self.params)
    res, op = operation!(operation_class, params) { [true, operation_class.present(params)] }
    op
  end

  def collection(*args)
    present(*args).tap do |op|
      @collection = op.model
    end
  end

  def run(operation_class, params=self.params, &block)
    res, op = operation!(operation_class, params) { operation_class.run(params) }

    yield op if res and block_given?

    Else.new(op, !res)
  end

  # The block passed to #respond is always run, regardless of the validity result.
  def respond(operation_class, options={}, params=self.params, &block)
    res, op   = operation!(operation_class, params, options) { operation_class.run(params) }
    namespace = options.delete(:namespace) || []

    return respond_with *namespace, op, options if not block_given?
    respond_with *namespace, op, options, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

private

  def process_params!(params)
  end

  # Normalizes parameters and invokes the operation (including its builders).
  def operation!(operation_class, params, options={}, &block)
    # Per default, only treat :html as non-document.
    options[:is_document] ||= request.format == :html ? false : true

    process_params!(params)
    res, op = Trailblazer::Endpoint.new(self, operation_class, params, request, options).(&block)
    setup_operation_instance_variables!(op)

    [res, op]
  end

  def setup_operation_instance_variables!(operation)
    @operation = operation
    @form      = operation.contract
    @model     = operation.model
  end


  # Note: this is not documented on purpose as this concept is experimental. I don't like it too much and prefer
  # returns in the valid block.
  class Else
    def initialize(op, run)
      @op  = op
      @run = run
    end

    def else
      yield @op if @run
    end
  end
end
