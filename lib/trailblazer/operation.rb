require 'trailblazer/flow'

module Trailblazer
  class Operation
    def self.run(params, &block) # Endpoint behaviour
      new.run(params)
    end


    def run(params) # to be overridden!!!
      # validate(nil, params, Contract)
    end

    def validate(model, params, contract_class=self.contract_class) # NOT to be overridden?!! it creates Result for us.
      contract = contract_class.new(model)

      if result = contract.validate(params)
        yield contract if block_given?
        return [result, model] # this is not Boolean
      end

      # we had raise here
      [result, model] # we wanna return model or contract here?
    end

    def contract_class
      self.class.const_get :Contract
    end

    Flow = Trailblazer::Flow # Operation::Flow
  end
end