module Trailblazer
  class Operation
    def self.flow(params, &block) # Endpoint behaviour
      res = new.flow(params)

      yield block if res
      return
    end

    def validate(contract, model, params)
      contract = contract.new(model)

      if result = contract.validate(params)
        yield contract if block_given?
        return model # this is not Boolean
      end

      # we had raise here
      result # we wanna return model or contract here?
    end
  end
end