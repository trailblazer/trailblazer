# Best practices for using contract.
#
# * inject contract instance via constructor to #contract
# * allow contract setup and memo via #contract(model, options)
# * allow implicit automatic setup via #contract and class.contract_class
#
# Needs Operation#model.
# Needs #[], #[]= skill dependency.
module Trailblazer
  class Operation
    module Contract
      def self.Build(name: "default", constant: nil, builder: nil)
        task = ->((options, flow_options), **circuit_options) do
          result = Build.(options, circuit_options, name: name, constant: constant, builder: builder)

          return Activity::TaskBuilder::Binary.binary_direction_for( result, Activity::Right, Activity::Left ),
            [options, flow_options]
        end

        { task: task, id: "contract.build" }
      end

      module Build
        # Build contract at runtime.
        def self.call(options, circuit_options, name: "default", constant: nil, builder: nil)
          # TODO: we could probably clean this up a bit at some point.
          contract_class = constant || options["contract.#{name}.class"] # DISCUSS: Injection possible here?
          model          = options[:model]
          name           = "contract.#{name}"

          options[name] =
            if builder
              call_builder( options, circuit_options, builder: builder, constant: contract_class, name: name )
            else
              contract_class.new(model)
            end
        end

        def self.call_builder(options, circuit_options, builder:raise, constant:raise, name:raise)
          # builder_options = Trailblazer::Context( options, constant: constant, name: name ) # options.merge( .. )

          # Trailblazer::Option::KW(builder).(builder_options, circuit_options)








          # FIXME: almost identical with Option::KW.
          # FIXME: see Nested::Options::Dynamic, the same shit
          tmp_options =  options.to_hash.merge(
            constant: constant,
            name:     name
          )

          Trailblazer::Option(builder).( options, tmp_options, circuit_options )
        end
      end

      module DSL
        def self.extended(extender)
          extender.extend(ClassDependencies)
          warn "[Trailblazer] Using `contract do...end` is deprecated. Please use a form class and the Builder( constant: <Form> ) option."
        end
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
end
