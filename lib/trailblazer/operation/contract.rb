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
    def self.included(includer)
      includer.extend DSL
      includer.include Validate
      # includer.| Build, before: Call # DISCUSS: future standard semantics. the plan is to make validate and contract another two pipeline steps.
    end

    module DSL
      # This is a DSL method. Use ::contract_class and ::contract_class= for the explicit version.
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


    module Builder
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

  public
    # Call like +contract(model)+ to create and memoize contract, e.g. for Composition.
    # Adds a step Contract::Build to build the contract automatically/implicitly.
    module Step
      def self.included(includer)
        includer.extend DSL
        includer.include Builder # #contract!
        includer.include Validate
        includer.include V # FIXME.
        includer.| Build, before: Call
      end

      module V
        # validate relies on a pre-computed contract from the pipeline.
        def validate(params, contract:self["contract"])
          super
        end
      end
    end

    module Validate
      def validate(params, contract:nil, **)
        if valid = validate_contract(contract, params)
          yield contract if block_given?
        else
          self[:errors] = contract.errors # FIXME: "contract.errors"
        end

        self["valid"] = valid
      end

      def validate_contract(contract, params)
        contract.validate(params)
      end
    end

    # The old way where you call Operation#contract at some point and then create and memoize the contract.
    # I think we should advise people to not overuse this.
    module Explicit
      def self.included(includer)
        includer.extend DSL
        includer.include Builder # #contract!
        includer.include Validate
        includer.include V # FIXME.
      end

      module V
        # validate relies on a pre-computed contract from the pipeline.
        def validate(params, **options)
          super(params, contract: contract(options))
        end
      end

      def contract(**kws)
        self["contract"] ||= contract_for(**kws)
      end
    end
  end

  Contract::Build = ->(operation, options) { operation["contract"] ||= operation.contract_for; operation }
end
