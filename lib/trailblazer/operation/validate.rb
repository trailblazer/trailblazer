module Trailblazer::Operation::Contract
  # result.contract = {..}
  # result.contract.errors = {..}
  # Deviate to left track if optional key is not found in params.
  # Deviate to left if validation result falsey.
  module Validate
    extend Trailblazer::Operation::Stepable

    def self.import!(operation, import, **args)
      import.(:&, ->(input, options) { extract_params!(input, options, **args) },
        name: "validate.params.extract")

      # call the actual contract.validate(params)
      import.(:&, ->(operation, options) { validate!(operation, options, **args) },
        name: "contract.validate")
      end

    def self.extract_params!(operation, options, key:nil, **)
      # FIXME: introduce nested pipes and pass composed input instead.
      options["params.validate"] = key ? options["params"][key] : options["params"]
    end

    def self.validate!(operation, options, name:"default", path:"contract", **)
      operation["result.#{path}"] = result = operation["contract.#{name}"].(options["params.validate"]) # FIXME: how could we deal here with polymorphic keys?
      result.success?
    end

    def validate(params, contract:self["contract.default"], path:"contract") # :params
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
