# Best practices for using contract.
#
# * inject contract instance via constructor to #contract
# * allow contract setup and memo via #contract(model, options)
# * allow implicit automatic setup via #contract and class.contract_class
#
# Needs Operation#model.
# Needs #[], #[]= skill dependency.
class Trailblazer::Operation
  module Contract
    def self.Build(name: "default", constant: nil, builder: nil)
      step = ->(direction, options, flow_options) { Build.(options, flow_options, name: name, constant: constant, builder: builder) }

      task = Trailblazer::Activity::Task::Binary( step )

      [ task, name: "contract.build" ]
    end

    module Build
      # Build contract at runtime.
      def self.call(options, flow_options, name: "default", constant: nil, builder: nil)
        # TODO: we could probably clean this up a bit at some point.
        contract_class = constant || options["contract.#{name}.class"] # DISCUSS: Injection possible here?
        model          = options["model"]
        name           = "contract.#{name}"

        options[name] =
          if builder
            call_builder( options, flow_options, builder: builder, constant: contract_class, name: name )
          else
            contract_class.new(model)
          end
      end

      def self.call_builder(options, flow_options, builder:raise, constant:raise, name:raise)
        # builder_options = Trailblazer::Context( options, constant: constant, name: name ) # options.merge( .. )

        # Trailblazer::Option::KW(builder).(builder_options, flow_options)








        # FIXME: almost identical with Option::KW.
        # FIXME: see Nested::Options::Dynamic, the same shit
        tmp_options =  options.to_hash.merge(
          constant: constant,
          name:     name
        )

        Trailblazer::Option(builder).( options, tmp_options, flow_options )
      end
    end

    module DSL
      # This is the class level DSL method.
      #   Op.contract #=> returns contract class
      #   Op.contract do .. end # defines contract
      #   Op.contract CommentForm # copies (and subclasses) external contract.
      #   Op.contract CommentForm do .. end # copies and extends contract.
      def contract(name=:default, constant=nil, base: Reform::Form, &block)
        heritage.record(:contract, name, constant, &block)

        path, form_class = Trailblazer::DSL::Build.new.({ prefix: :contract, class: base, container: self }, name, constant, block)

        self[path] = form_class
      end
    end # Contract
  end
end
