# Best practices for using contract.
#
# * inject contract instance via constructor to #contract
# * allow contract setup and memo via #contract(model, options)
# * allow implicit automatic setup via #contract and class.contract_class
module Trailblazer::Operation::Contract
  module Initialize
    def initialize(**args)
      super
      @contract       = args[:contract] # DISCUSS: how will this behave performance-wise in 1.2?
      @contract_class = args[:contract_class] # DISCUSS: how will this behave performance-wise in 1.2?
    end
  end

  def self.included(includer)
    includer.send :include, Initialize

    includer.extend Uber::InheritableAttr
    includer.inheritable_attr :contract_class
    includer.extend DSL
  end
  # TODO: use dry-constructor or whatever for a unified initialize interface.

  module DSL
    # This is a DSL method. Use ::contract_class and ::contract_class= for the explicit version.
    #   Op.contract #=> returns contract class
    #   Op.contract do .. end # defines contract
    #   Op.contract CommentForm # copies (and subclasses) external contract.
    #   Op.contract CommentForm do .. end # copies and extends contract.
    def contract(constant=nil, &block)
      return contract_class unless constant or block_given?

      self.contract_class= Class.new(constant) if constant
      contract_class.class_eval(&block) if block_given?
    end
  end


  # Instantiate the contract, either by using the user's contract passed into #validate
  # or infer the Operation contract.
  def contract_for(model=nil, options={}, contract_class=nil)
    model          ||= self.model
    contract_class ||= self.contract_class

    contract!(model, options, contract_class)
  end

  # Override to construct your own contract.
  def contract!(model, options, contract_class)
    contract_class.new(model, options)
  end

public
  # Call like +contract(model)+ to create and memoize contract, e.g. for Composition.
  def contract(*args)
    @contract ||= contract_for(*args)
  end

#private
  def contract_class
    @contract_class || self.class.contract_class
  end
end

# initialize chain could be solved with pipetree.
