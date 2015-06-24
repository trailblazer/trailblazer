require "trailblazer/endpoint"

module Trailblazer::Operation::Controller
private
  def form(operation_class, params=self.params) # consider private.
    process_params!(params)

    @operation = operation_class.present(params)
    @form      = @operation.contract
    @model     = @operation.model

    yield @operation if block_given?
  end

  # Doesn't run #validate.
  # TODO: allow only_setup.
  # TODO: dependency to CRUD (::model_name)
  def present(operation_class, params=self.params)
    res, op = operation!(operation_class, params) { [true, operation_class.present(params)] }

    yield op if block_given?
    # respond_with op
    # TODO: implement respond(present: true)
  end

  def collection(operation_class, params=self.params)
    # TODO: merge with #present.
    res, op = operation!(operation_class, params) { [true, operation_class.present(params)] }
    @collection = @model

    yield op if block_given?
  end

  # full-on Op[]
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

  # Endpoint::Invocation
  def run(operation_class, params=self.params, &block)
    res, op = operation!(operation_class, params) { operation_class.run(params) }

    yield op if res and block_given?

    Else.new(op, !res)
  end

  # The block passed to #respond is always run, regardless of the validity result.
  def respond(operation_class, params=self.params, respond_options = {}, &block)
    res, op = operation!(operation_class, params) { operation_class.run(params) }

    return respond_with op, respond_options if not block_given?
    respond_with op, respond_options, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

  def process_params!(params)
  end

  # Normalizes parameters and invokes the operation (including its builders).
  def operation!(operation_class, params, &block)
    Trailblazer::Endpoint.new(self, operation_class, params, request, self.class._operation).(&block)
  end

  def setup_operation_instance_variables!(operation)
    @operation = operation
    @form      = operation.contract
    @model     = operation.model
  end

  def self.included(includer)
    includer.extend Uber::InheritableAttr
    includer.inheritable_attr :_operation
    includer._operation = {document_formats: {}}
    includer.extend ClassMethods
  end

  module ClassMethods
    def operation(options)
      _operation[:document_formats][options[:document_formats]] = true
    end
  end
end
