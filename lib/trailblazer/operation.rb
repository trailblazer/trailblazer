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



    def run(params) # to be overridden!!!
      # validate(nil, params, Contract)
    end

    def validate(model, params, contract_class=self.contract_class) # NOT to be overridden?!! it creates Result for us.
      contract = contract_class.new(model)

      if result = contract.validate(params)
        yield contract if block_given?
        return [result, contract] # this is not Boolean
      end

      # we had raise here
      [result, contract]
    end

    def contract_class
      self.class.const_get :Contract
    end

    Flow = Trailblazer::Flow # Operation::Flow
  end
end