module Trailblazer::Operation::Contract
  # result.contract = {..}
  # result.contract.errors = {..}
  # Deviate to left track if optional key is not found in params.
  # Deviate to left if validation result falsey.
  module Validate
    extend Trailblazer::Operation::Macro

    def self.import!(operation, import, skip_extract:false, **args)
      skip_extract = true if args[:representer]

      import.(:&, ->(input, options) { extract_params!(input, options, **args) },
        name: "validate.params.extract") unless skip_extract

      # call the actual contract.validate(params)
      import.(:&, ->(operation, options) { validate!(operation, options, **args) },
        name: "contract.validate")
      end

    def self.extract_params!(operation, options, key:nil, **)
      # FIXME: introduce nested pipes and pass composed input instead.
      options["params.validate"] = key ? options["params"][key] : options["params"]
    end

    def self.validate!(operation, options, name:"default", representer: nil, from: "document.json", format: :json, **)
      path     = "contract.#{name}"
      contract = operation[path]

      # this is for 1.1-style compatibility and should be removed once we have Deserializer in place:
      operation["result.#{path}"] = result =
        if representer
          # use "document.json" as the body and let the representer deserialize to the contract.
          # this will be simplified once we have Deserializer.
          # translates to contract.("{document: bla}") { MyRepresenter.new(contract).from_json .. }
          contract.(options[from]) { |document| representer.new(contract).send("from_#{format}", document) }
        else
          # let Reform handle the deserialization.
          contract.(options["params.validate"])
        end

      result.success?
    end
  end
end
