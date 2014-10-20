module Trailblazer::Operation::Controller
  # TODO: test me.

  ## no #validate!
  # TODO: test without block, e.g. for #show
  def present(operation_class, params=self.params)
    unless request.format == :html
      # FIXME: how do we know the "name" of the Operation body?
      # return respond_with User::Update::JSON.run(params.merge(user: request.body.string))
      concept_name = operation_class.to_s.split("::").first.downcase # TODO: holy shit test this properly

      res, op = operation_class.const_get(:JSON).run(params.merge(concept_name => request.body.string))

      return respond_with(op)
    end


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

  # TODO: WITH BLOCK!
  def respond(operation_class, params=self.params)
    res, @operation = operation_class.run(params)

    @form      = @operation.contract
    @model     = @operation.model

    yield @operation if block_given?

    respond_with @operation
  end
end
