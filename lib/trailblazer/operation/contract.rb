# Best practices for using contract.
#
# * inject contract instance via constructor to #contract
# * allow contract setup and memo via #contract(model, options)
# * allow implicit automatic setup via #contract and class.contract_class
#
# Needs Operation#model.
# Needs #[], #[]= skill dependency.
module Trailblazer::Operation::Contract
  def self.included(includer)
    includer.extend DSL
    includer.include Validate

    includer.extend Declarative::Heritage::Inherited
    includer.extend Declarative::Heritage::DSL
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
  # until here, this code is totally generic and could be the same for model, contract, policy, etc.

  # Instantiate the contract, either by using the user's contract passed into #validate
  # or infer the Operation contract.
  def contract_for(model=nil, options={}, contract_class=nil)
    model          ||= self.model
    contract_class ||= self["contract.default.class"]

    contract!(model, options, contract_class)
  end

  # Override to construct your own contract.
  def contract!(model, options, contract_class)
    contract_class.new(model, options)
  end

public
  # Call like +contract(model)+ to create and memoize contract, e.g. for Composition.
  def contract(*args)
    self["contract"] ||= result[:contract] = contract_for(*args)
  end

  module Validate
  private
    # Instantiates the operation's contract and validates the params with it.
    # Signature: validate(params, model=nil, options={}, contract_class=nil)
    def validate(params, *args)
      contract(*args)

      if valid = validate_contract(params)
        yield contract if block_given?
      else
        result[:errors] = contract.errors
      end

      result[:valid] = valid
    end

    def validate_contract(params)
      contract.validate(params)
    end
  end

  module Raise
    def validate(*)
      super.tap do |res|
        raise!(contract) unless res
      end
    end

    # DISCUSS: this is now a test-specific optional feature, so should we really keep it here?
    def raise!(contract)
      raise ::Trailblazer::Operation::InvalidContract.new(contract.errors.to_s)
    end
  end
end

class Trailblazer::Operation::InvalidContract < RuntimeError
end

# initialize chain could be solved with pipetree.
