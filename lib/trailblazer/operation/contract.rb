# Best practices for using contract.
#
# * inject contract instance via constructor to #contract
# * allow contract setup and memo via #contract(model, options)
# * allow implicit automatic setup via #contract and class.contract_class
#
# Needs Operation#model.
# Needs #[], #[]= skill dependency.
module Trailblazer::Operation::Contract
  module Build
    # bla build contract at runtime.
    def self.build_contract!(operation, options, name:"default", constant:nil, builder: nil)
      # TODO: we could probably clean this up a bit at some point.
      contract_class = constant || options["contract.#{name}.class"]
      model          = operation["model"] # FIXME: model.default

      return operation["contract.#{name}"] = Uber::Option[builder].(operation, constant: contract_class, model: model) if builder

      operation["contract.#{name}"] = contract_class.new(model)
    end

    def self.import!(operation, import, **args)
      import.(:>, ->(operation, options) { build_contract!(operation, options, **args) },
        name: "contract.build")
    end
  end

  def self.Build(*args, &block)
    [ Build, args, block ]
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
