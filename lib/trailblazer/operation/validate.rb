class Trailblazer::Operation
  module Contract
    # result.contract = {..}
    # result.contract.errors = {..}
    # Deviate to left track if optional key is not found in params.
    # Deviate to left if validation result falsey.
    def self.Validate(skip_extract: false, name: "default", representer: false, key: nil) # DISCUSS: should we introduce something like Validate::Deserializer?
      params_path = "contract.#{name}.params" # extract_params! save extracted params here.

      extract  = Validate::Extract.new( key: key, params_path: params_path ).freeze
      validate = Validate.new( name: name, representer: representer, params_path: params_path ).freeze

      # Return the Validate::Call task if the first step, the params extraction, is not desired.
      if skip_extract || representer
        return { task: Trailblazer::Activity::Task::Binary( validate ), id: "contract.#{name}.call" }
      end


      # Build a simple Railway {Activity} for the internal flow.
      activity = Trailblazer::Activity::Railway.build do # FIXME: make Activity.build(builder: Railway) do end an <Activity>
        step Trailblazer::Activity::Task::Binary( extract ),  id: "#{params_path}_extract"
        step Trailblazer::Activity::Task::Binary( validate ), id: "contract.#{name}.call"
      end

      # DISCUSS: use Nested here?
      # Nested.operation_class.Nested( activity, id: "contract.#{name}.validate" )
      { task: activity, id: "contract.#{name}.validate", plus_poles: Trailblazer::Activity::Magnetic::DSL::PlusPoles.from_outputs(activity.outputs) }
    end

    class Validate
      # Task: extract the contract's input from params by reading `:key`.
      class Extract
        def initialize(key:nil, params_path:nil)
          @key, @params_path = key, params_path
        end

        def call( (options, flow_options), **circuit_options )
          options[@params_path] = @key ? options["params"][@key] : options["params"]
        end
      end

      def initialize(name:"default", representer:false, params_path:nil)
        @name, @representer, @params_path = name, representer, params_path
      end

      # Task: Validates contract `:name`.
      def call( (options, flow_options), **circuit_options )
        validate!(
          options,
          representer: options["representer.#{@name}.class"] ||= @representer, # FIXME: maybe @representer should use DI.
          params_path: @params_path
        )
      end

      def validate!(options, representer:false, from: "document", params_path:nil)
        path     = "contract.#{@name}"
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
