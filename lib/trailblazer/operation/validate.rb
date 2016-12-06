module Trailblazer::Operation::Contract
  # result.contract = {..}
  # result.contract.errors = {..}
  # Deviate to left track if optional key is not found in params.
  # Deviate to left if validation result falsey.
  module Validate
    def self.import!(operation, import, skip_extract:false, name: "default", representer:false, **args) # DISCUSS: should we introduce something like Validate::Deserializer?
      if representer
        skip_extract = true
        operation["representer.#{name}.class"] = representer
      end

      import.(:&, ->(input, options) { extract_params!(input, options, **args) },
        name: "validate.params.extract") unless skip_extract

      # call the actual contract.validate(params)
      # DISCUSS: should we pass the representer here, or do that in #validate! i'm still mulling over what's the best, most generic approach.
      import.(:&, ->(operation, options) { validate!(operation, options, name: name, representer: options["representer.#{name}.class"], **args) },
        name: "contract.validate")
      end

    def self.extract_params!(operation, options, key:nil, **)
      # TODO: introduce nested pipes and pass composed input instead.
      options["params.validate"] = key ? options["params"][key] : options["params"]
    end

    def self.validate!(operation, options, name: nil, representer:false, from: "document", **)
      path     = "contract.#{name}"
      contract = operation[path]

      # this is for 1.1-style compatibility and should be removed once we have Deserializer in place:
      operation["result.#{path}"] = result =
        if representer
          # use "document" as the body and let the representer deserialize to the contract.
          # this will be simplified once we have Deserializer.
          # translates to contract.("{document: bla}") { MyRepresenter.new(contract).from_json .. }
          contract.(options[from]) { |document| representer.new(contract).parse(document) }
        else
          # let Reform handle the deserialization.
          contract.(options["params.validate"])
        end

      result.success?
    end
  end

  def self.Validate(*args, &block)
    [ Validate, args, block ]
  end
end
