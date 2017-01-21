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
    def self.Build(name:"default", constant:nil, builder: nil)
      step = ->(input, options) { Build.for(input, options, name: name, constant: constant, builder: builder) }

      [ step, name: "contract.build" ]
    end

    module Build
      # bla build contract at runtime.
      def self.for(operation, options, name:"default", constant:nil, builder: nil)
        # TODO: we could probably clean this up a bit at some point.
        contract_class = constant || options["contract.#{name}.class"]
        model          = options["model"] # FIXME: model.default
        name           = "contract.#{name}"

        return options[name] = Option::KW.(builder).(operation, options, constant: contract_class, name: name) if builder

        options[name] = contract_class.new(model)
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
