class Trailblazer::Operation
  module Contract
    # result.contract = {..}
    # result.contract.errors = {..}
    # Deviate to left track if optional key is not found in params.
    # Deviate to left if validation result falsey.
    module Validate
      def self.import!(operation, import, skip_extract:false, name: "default", representer:false, key: nil) # DISCUSS: should we introduce something like Validate::Deserializer?
        if representer
          skip_extract = true
          operation["representer.#{name}.class"] = representer
        end

        params_path = "contract.#{name}.params" # extract_params! save extracted params here.

        import.(:&, ->(input, options) { extract_params!(input, options, key: key, path: params_path) },
          name: params_path) unless skip_extract

        # call the actual contract.validate(params)
        # DISCUSS: should we pass the representer here, or do that in #validate! i'm still mulling over what's the best, most generic approach.
        import.(:&, ->(operation, options) do
            validate!(operation, options, name: name, representer: options["representer.#{name}.class"], key: key, params_path: params_path)
          end,
          name: "contract.#{name}.validate", # visible name of the pipe step.
        )
        end

      def self.extract_params!(operation, options, key:nil, path:nil)
        # TODO: introduce nested pipes and pass composed input instead.
        options[path] = key ? options["params"][key] : options["params"]
      end

      def self.validate!(operation, options, name: nil, representer:false, from: "document", params_path:nil, **)
        path     = "contract.#{name}"
        contract = options[path]

        # this is for 1.1-style compatibility and should be removed once we have Deserializer in place:
        options["result.#{path}"] = result =
          if representer
            # use "document" as the body and let the representer deserialize to the contract.
            # this will be simplified once we have Deserializer.
            # translates to contract.("{document: bla}") { MyRepresenter.new(contract).from_json .. }
            contract.(options[from]) { |document| representer.new(contract).parse(document) }
          else
            # let Reform handle the deserialization.
            contract.(options[params_path])
          end

        result.success?
      end
    end
  end

  DSL.macro!(:Validate, Contract::Validate, Contract.singleton_class)
end
