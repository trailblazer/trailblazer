module Trailblazer::Operation::Procedural
  module Validate
    def validate(params, contract:self["contract.default"], path:"contract.default") # :params
      # DISCUSS: should we only have path here and then look up contract ourselves?
      result = validate_contract(contract, params) # run validation.  # FIXME: must be overridable.

      self["result.#{path}"] = result

      if valid = result.success? # FIXME: to_bool or success?
        yield result if block_given?
      else
        # self["errors.#{path}"] = result.errors # TODO: remove me
      end

      valid
    end

    def validate_contract(contract, params)
      contract.(params)
    end
  end
end
