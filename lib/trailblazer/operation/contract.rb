Reform::Form.class_eval do # THIS IS OF COURSE PROTOTYPING!
  def call(params, &block)
    bool = validate(params, &block)
    Result.new(self)
  end

  class Result < SimpleDelegator
    def success?
      errors.empty?
    end
  end
end
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
    # bla build contract at runtime.
    def self.build_contract!(operation, options, name:"default", constant:nil, builder: nil)
      # TODO: we could probably clean this up a bit at some point.
      return operation["contract.#{name}"] = Uber::Option[builder].(operation) if builder

      contract_class = constant || options["contract.#{name}.class"]
      operation["contract.#{name}"] = contract_class.new(operation["model"])
    end

    extend Stepable # ::[]

    def self.import!(operation, import, **args)
      import.(:>, ->(operation, options) { build_contract!(operation, options, **args) },
        name: "contract.build")
    end

    # TODO: allow users to use the old way with this.
    module ContractFor # FIXME: rename!
      # Instantiate the contract, either by using the user's contract passed into #validate
      # or infer the Operation contract.
      def contract_for(model:self["model"], options:{}, contract_class:self["contract.default.class"])
        contract!(model: model, options: options, contract_class: contract_class)
      end

      # Override to construct your own contract.
      def contract!(model:nil, options:{}, contract_class:nil)
        contract_class.new(model, options)
      end
    end

    module DSL
      # This is the class level DSL method.
      #   Op.contract #=> returns contract class
      #   Op.contract do .. end # defines contract
      #   Op.contract CommentForm # copies (and subclasses) external contract.
      #   Op.contract CommentForm do .. end # copies and extends contract.
      def contract(name=:default, constant=nil, &block)
        heritage.record(:contract, name, constant, &block)

        path, form_class = Trailblazer::DSL::Build.new.({ prefix: :contract, class: Reform::Form, container: self }, name, constant, block)

        self[path] = form_class
      end
    end
  end # Contract
end
