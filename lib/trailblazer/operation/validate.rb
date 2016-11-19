module Trailblazer::Operation::Contract
  # result.contract = {..}
  # result.contract.errors = {..}
  # Deviate to left track if optional key is not found in params.
  # Deviate to left if validation result falsey.
  module Validate
    extend Trailblazer::Operation::Stepable

    def self.import!(operation, import, key: nil, name: "default")
      import.(:&, ->(input, options) { options["params.validate"] = key ? options["params"][key] : options["params"] }, # FIXME: introduce nested pipes and pass composed input instead.
        name: "validate.params.extract")

      # call the actual contract.validate(params)
      import.(:&, ->(operation, options) {

        operation.validate(options["params.validate"], contract: operation["contract.#{name}"]) }, # FIXME: how could we deal here with polymorphic keys?

        name: "contract.validate")

      operation.send :include, self
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
