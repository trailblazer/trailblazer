module Trailblazer::Operation::Controller
  # TODO: test me.

private
  def form(operation_class, params=self.params) # consider private.
    process_params!(params)

    @operation = operation_class.new.present(params)
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
    respond_with op
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

      params.merge!(concept_name => request.body.string)
    end

    res, @operation = yield # Create.run(params)
    @form  = @operation.contract
    @model = @operation.model

    [res, @operation] # DISCUSS: do we need result here? or can we just go pick op.valid?
  end
end
