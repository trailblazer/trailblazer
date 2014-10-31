module Trailblazer::Operation::Controller
  # TODO: test me.

private
  # Doesn't run #validate, just for HTML (e.g. #new and #edit).
  def present(operation_class, params=self.params)
    process_params!(params)

    @operation = operation_class.new(:validate => false).run(params).last # FIXME: make that available via Operation.
    @form      = @operation.contract
    @model     = @operation.model

    yield @operation if block_given?
  end

  # full-on Op[]
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
    unless request.format == :html
      # FIXME: how do we know the "name" of the Operation body?
      # return respond_with User::Update::JSON.run(params.merge(user: request.body.string))
      concept_name = operation_class.to_s.split("::").first.downcase # TODO: holy shit test this properly

      res, op = operation_class.const_get(:JSON).run(params.merge(concept_name => request.body.string))



      respond_with op
      return Else.new(op, false)
    end

    # only if format==:html!!!!!!!
    res, @operation = operation_class.run(params)

    @form      = @operation.contract
    @model     = @operation.model

    yield @operation if res

    Else.new(op, !res)
  end
  private :present, :run

  # TODO: what if it's JSON and we want OP:JSON to deserialise etc?
  def respond(operation_class, params=self.params, &block)
    process_params!(params)

    res, @operation = operation_class.run(params)

    @form      = @operation.contract
    @model     = @operation.model

    return respond_with @operation if not block_given?

    op = @operation
    respond_with @operation, &Proc.new { |formats| block.call(op, formats) } if block_given?
  end

  def process_params!(params)
  end
end
