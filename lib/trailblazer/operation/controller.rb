module Trailblazer::Operation::Controller
  # TODO: test me.

  ## no #validate!
  # TODO: test without block, e.g. for #show
  def present(operation_class, params=self.params)
    unless request.format == :html
      # FIXME: how do we know the "name" of the Operation body?
      # return respond_with User::Update::JSON.run(params.merge(user: request.body.string))
      res, op = operation_class.const_get(:JSON).run(params.merge(user: request.body.string))

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
      res, op = User::Update::JSON.run(params.merge(user: request.body.string))



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
end
