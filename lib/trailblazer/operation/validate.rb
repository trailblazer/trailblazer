module Trailblazer
  class Operation
    module Contract
      # result.contract = {..}
      # result.contract.errors = {..}
      # Deviate to left track if optional key is not found in params.
      # Deviate to left if validation result falsey.
      def self.Validate(skip_extract: false, name: "default", representer: false, key: nil) # DISCUSS: should we introduce something like Validate::Deserializer?
        params_path = "contract.#{name}.params" # extract_params! save extracted params here.

        extract  = Validate::Extract.new( key: key, params_path: params_path ).freeze
        validate = Validate.new( name: name, representer: representer, params_path: params_path ).freeze

        # Build a simple Railway {Activity} for the internal flow.
        activity = Module.new do
          extend Activity::Railway(name: "Contract::Validate")

          step extract,  id: "#{params_path}_extract" unless skip_extract || representer
          step validate, id: "contract.#{name}.call"
        end

        # activity, _ = activity.decompose

        # DISCUSS: use Nested here?
        { task: activity, id: "contract.#{name}.validate", outputs: activity.outputs }
      end

      class Validate
        # Task: extract the contract's input from params by reading `:key`.
        class Extract
          def initialize(key:nil, params_path:nil)
            @key, @params_path = key, params_path
          end

          def call( ctx, params:, ** )
            ctx[@params_path] = @key ? params[@key] : params
          end
        end

        def initialize(name:"default", representer:false, params_path:nil)
          @name, @representer, @params_path = name, representer, params_path
        end

        # Task: Validates contract `:name`.
        def call( ctx, ** )
          validate!(
            ctx,
            representer: ctx["representer.#{@name}.class"] ||= @representer, # FIXME: maybe @representer should use DI.
            params_path: @params_path
          )
        end

        def validate!(options, representer:false, from: :document, params_path:nil)
          path     = "contract.#{@name}"
          contract = options[path]

          # this is for 1.1-style compatibility and should be removed once we have Deserializer in place:
          options["result.#{path}"] = result =
            if representer
              # use :document as the body and let the representer deserialize to the contract.
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
  end # Operation
end
