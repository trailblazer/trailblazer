require 'trailblazer/flow'

module Trailblazer
  class Operation
    class << self
      def run(*params, &block) # Endpoint behaviour
        new.run(*params)
      end

      # ::call only returns the Contract instance (or whatever was returned from #validate).
      # This is useful in tests or in irb, e.g. when using Op as a factory and you already know it's valid.
      def call(*params)
        new(:raise_on_invalid => true).run(*params).last
      end
      alias_method :[], :call

      def contract(*params)
        new(:validate => false).run(*params).last
      end
    end


    def initialize(options={})
      @valid            = true
      # DISCUSS: use reverse_merge here?
      @validate         = options[:validate] == false ? false : true
      @raise_on_invalid = options[:raise_on_invalid] || false
    end

    # Calling this method from the overriding method (aka "super model")
    # will return a result array that works with the existing invocation protocol.
    # As no validation happens, the result will always be true. Whatever is passed to super
    # is returned in the result array.
    #
    #   def run(params)
    #     model = Comment.create(params) # NO validation happens.
    #     super model
    #   end
    #
    #   Operation.run(body: "Fabulous!") #=> [true, <Comment body: "Fabulous!">]
    def run(*params)
      setup!(*params) # where do we assign/find the model?

      [process(*params), @valid].reverse
    end

  private
    def setup!(*params)
    end

    def validate(params, model, contract_class=nil) # NOT to be overridden?!! it creates Result for us.
      contract = contract_for(contract_class, model)

      return contract unless @validate # Op.contract will return here.

      if @valid = contract.validate(params)
        yield contract if block_given?
      else
        raise!(contract)
      end

      contract
    end

    def invalid!(result)
      @valid = false
      result
    end

    # When using Op::[], an invalid contract will raise an exception.
    def raise!(contract)
      raise InvalidContract.new(contract.errors.to_s) if @raise_on_invalid
    end

    def contract_class
      self.class.const_get :Contract
    end

    # Instantiate the contract, either by using the user's contract passed into #validate
    # or infer the Operation contract.
    def contract_for(contract_class, *model)
      (contract_class || send(:contract_class)).new(*model)
    end

    Flow = Trailblazer::Flow # Operation::Flow

    class InvalidContract < RuntimeError
    end
  end
end

# run
#   setup
#   process
#     contract
#     validate
