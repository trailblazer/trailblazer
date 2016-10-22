require "reform"

module Trailblazer
  class Operation
    require "trailblazer/operation/builder"
    extend Builder # imports ::builder_class and ::build_operation.

    extend Uber::InheritableAttr
    inheritable_attr :contract_class
    self.contract_class = Reform::Form.clone

    class << self
      def run(params, &block) # Endpoint behaviour
        res, op = build_operation(params).run

        if block_given?
          yield op if res
          return op
        end

        [res, op]
      end

      # Like ::run, but yield block when invalid.
      def reject(*args)
        res, op = run(*args)
        yield op if res == false
        op
      end

      # ::call only returns the Operation instance (or whatever was returned from #validate).
      # This is useful in tests or in irb, e.g. when using Op as a factory and you already know it's valid.
      def call(params)
        build_operation(params, raise_on_invalid: true).run.last
      end

      def [](*args) # TODO: remove in 1.2.
        warn "[Trailblazer] Operation[] is deprecated. Please use Operation.() and have a nice day."
        call(*args)
      end

      # Runs #setup! but doesn't process the operation.
      def present(params)
        build_operation(params)
      end

      # This is a DSL method. Use ::contract_class and ::contract_class= for the explicit version.
      #   Op.contract #=> returns contract class
      #   Op.contract do .. end # defines contract
      #   Op.contract CommentForm # copies (and subclasses) external contract.
      #   Op.contract CommentForm do .. end # copies and extends contract.
      def contract(constant=nil, &block)
        return contract_class unless constant or block_given?

        self.contract_class= Class.new(constant) if constant
        contract_class.class_eval(&block) if block_given?
      end
    end


    def initialize(params, options={})
      @options          = options
      @valid            = true

      setup!(params) # assign/find the model
    end

    #   Operation.run(body: "Fabulous!") #=> [true, <Comment body: "Fabulous!">]
    def run
      process(@params)

      [valid?, self]
    end

    attr_reader :model

    def errors
      contract.errors
    end

    def valid?
      @valid
    end

  private
    module Setup
      attr_writer :model

      def setup!(params)
        params = assign_params!(params)
        setup_params!(params)
        build_model!(params)
        params # TODO: test me.
      end

      def assign_params!(params)
        @params = params!(params)
      end

      # Overwrite #params! if you need to change its structure, by returning a new params object
      # from this method.
      # This is helpful if you don't want to change the original via #setup_params!.
      def params!(params)
        params
      end

      def setup_params!(params)
      end

      def build_model!(*args)
        assign_model!(*args) # @model = ..
        setup_model!(*args)
      end

      def assign_model!(*args)
        @model = model!(*args)
      end

      # Implement #model! to find/create your operation model (if required).
      def model!(params)
      end

      # Override to add attributes that can be inferred from params.
      def setup_model!(params)
      end
    end
    include Setup

    # Instantiates the operation's contract and validates the params with it.
    # Signature: validate(params, model=nil, options={}, contract_class=nil)
    def validate(params, *args)
      contract(*args)

      if @valid = validate_contract(params)
        yield contract if block_given?
      else
        raise!(contract)
      end

      @valid
    end

    def validate_contract(params)
      contract.validate(params)
    end

    def invalid!(result=self)
      @valid = false
      result
    end

    # When using Op.(), an invalid contract will raise an exception.
    def raise!(contract)
      raise InvalidContract.new(contract.errors) if @options[:raise_on_invalid]
    end

    # Instantiate the contract, either by using the user's contract passed into #validate
    # or infer the Operation contract.
    def contract_for(model=nil, options={}, contract_class=nil)
      model          ||= self.model
      contract_class ||= self.class.contract_class

      contract!(model, options, contract_class)
    end

    # Override to construct your own contract.
    def contract!(model, options, contract_class)
      contract_class.new(model, options)
    end

  public
    # Call like +contract(model)+ to create and memoize contract, e.g. for Composition.
    def contract(*args)
      args = deprecate_contract_args(*args)
      @contract ||= contract_for(*args)
    end

    def deprecate_contract_args(*args) # TODO: remove in 1.3.
      return args if args.size != 2
      return args if args[1].is_a?(Hash) # the old API was contract(model, contract_class).

      warn "[Trailblazer] The signature of Operation#contract has changed: contract(model, options={}, contract_class)."
      [args[0], {}, args[1]]
    end

    class InvalidContract < RuntimeError

      attr_reader :errors

      def initialize(errors)
        super(errors.to_s)
        @errors = errors.messages
      end

    end
  end
end
