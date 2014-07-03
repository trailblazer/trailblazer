require 'trailblazer/flow'

module Trailblazer
  class Operation
    class Contract #< Reform::Form
      def initialize(*)
      end
      def validate(params)
        params
      end
    end

    def self.run(params, &block) # Endpoint behaviour
      new.run(params)
    end

    def run(params) # to be overridden!!!
      validate(Contract, nil, params)
    end

    def validate(contract, model, params) # NOT to be overridden?!! it creates Result for us.
      contract = contract.new(model)

      if result = contract.validate(params)
        yield contract if block_given?
        return [result, model] # this is not Boolean
      end

      # we had raise here
      [result, model] # we wanna return model or contract here?
    end

    Flow = Trailblazer::Flow # Operation::Flow
  end
end