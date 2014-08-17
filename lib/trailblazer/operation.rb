require 'trailblazer/flow'

module Trailblazer
  class Operation
    class << self
      def run(params, &block) # Endpoint behaviour
        new.run(params)
      end

      # ::call only returns the Contract instance (or whatever was returned from #validate).
      # This is useful in tests when using Op as a factory and you already know its valid.
      def call(params)
        run(params).last
      end
      alias_method :[], :call
    end


    def initialize
      @valid = true
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
    def run(params)
      setup!(params)
      # where do we assign/find the model?

      [process(params), @valid].reverse
      # validate(nil, params, Contract)
    end

  private
    def setup!(params)
    end

    def validate(model, params, contract_class=send(:contract_class)) # NOT to be overridden?!! it creates Result for us.
      contract = contract_class.new(model)

      if @valid = contract.validate(params)
        yield contract if block_given?
      end

      contract
    end

    def invalid!(result)
      @valid = false
      result
    end

    def contract_class
      self.class.const_get :Contract
    end

    Flow = Trailblazer::Flow # Operation::Flow
  end
end