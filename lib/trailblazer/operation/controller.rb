module Trailblazer::Operation::Controller
  # TODO: test me.

private
  def form(operation_class, params=self.params) # consider private.
    process_params!(params)

    @operation = operation_class.present(params)
    @form      = @operation.contract
    @model     = @operation.model

    yield @operation if block_given?
  end

  def collection(operation_class, params=self.params, &block)
    @fetching_collection = true
    res, op = operation!(operation_class, params) { operation_class.collection(params) }

    yield op if res and block_given?

    Else.new(op, !res)
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
  def respond(operation_class, params=self.params, &block)
    res, op = operation!(operation_class, params) { operation_class.run(params) }

    return respond_with op if not block_given?
    respond_with op, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

  def process_params!(params)
  end

  # Normalizes parameters and invokes the operation (including its builders).
  def operation!(operation_class, params)
    process_params!(params)

    unless request.format == :html
      # this is what happens:
      # respond_with Comment::Update::JSON.run(params.merge(comment: request.body.string))
      concept_name = operation_class.model_class.to_s.underscore # this could be renamed to ::concept_class soon.
      request_body = request.body.respond_to?(:string) ? request.body.string : request.body.read

      params.merge!(concept_name => request_body)
    end

    res, @operation = yield # Create.run(params)

    if @fetching_collection
      setup_operation_collection_variables!
    else
      setup_operation_instance_variables!
    end

    [res, @operation] # DISCUSS: do we need result here? or can we just go pick op.valid?
  end

  def setup_operation_instance_variables!
    @form = @operation.contract
    @model = @operation.model
  end
  
  def setup_operation_collection_variables!
    @collection = @operation.collection
    operation_collection_name = @operation.collection.model.table_name
    instance_variable_set(:"@#{operation_collection_name}", @collection)
  end
end
