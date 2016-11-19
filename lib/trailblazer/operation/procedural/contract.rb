module Trailblazer::Operation::Procedural
  # THIS IS UNTESTED, PRIVATE API AND WILL BE REMOVED SOON.
  module Contract
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
end
