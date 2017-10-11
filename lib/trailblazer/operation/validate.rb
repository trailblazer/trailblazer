class Trailblazer::Operation
  module Contract
    # result.contract = {..}
    # result.contract.errors = {..}
    # Deviate to left track if optional key is not found in params.
    # Deviate to left if validation result falsey.
    def self.Validate(skip_extract: false, name: "default", representer: false, key: nil) # DISCUSS: should we introduce something like Validate::Deserializer?
      params_path = "contract.#{name}.params" # extract_params! save extracted params here.

      # Return the Validate::Call task if the first step, the params extraction, is not desired.
      if skip_extract || representer
        return Validate::Call(name: name, representer: representer, params_path: params_path)
      end

      extract_validate = Class.new(Nested.operation_class) do # TODO: use Base so compat works.
        step Validate::Extract(key: key, params_path: params_path)
        step Validate::Call(name: name, representer: representer, params_path: params_path)
      end

      Nested.operation_class.Nested( extract_validate, name: "contract.#{name}.validate" )
    end

    module Validate
      # Macro: extract the contract's input from params by reading `:key`.
      def self.Extract(key:nil, params_path:nil)
        # TODO: introduce nested pipes and pass composed input instead.
        step = ->( (options, flow_options), **circuit_options ) do
          options[params_path] = key ? options["params"][key] : options["params"]
        end

        task = Trailblazer::Activity::Task::Binary( step )

        { task: task, node_data: { id: params_path } }
      end

      # Macro: Validates contract `:name`.
      def self.Call(name:"default", representer:false, params_path:nil)
        step = ->( (options, flow_options), **circuit_options ) {
          validate!(options, name: name, representer: options["representer.#{name}.class"], params_path: params_path)
        }

        task = Trailblazer::Activity::Task::Binary( step )
        # Pipetree::Step.new( step, "representer.#{name}.class" => representer ) # FIXME!

        { task: task, node_data: { id: "contract.#{name}.call" } }
      end

      def self.validate!(options, name:nil, representer:false, from: "document", params_path:nil)
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
end
