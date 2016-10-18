require "test_helper"

# [Trailblazer] Operation::contract_class is deprecated, please use Operation::["contract.class"]
# [Trailblazer] Operation::contract_class= is deprecated, please use Operation::["contract.class"]=

class DeprecationsTest < Minitest::Spec
  require "trailblazer/operation/contract"

  class Delete < Trailblazer::Operation
    include Contract
    self.contract_class
    self.contract_class = Object
    contract # TODO: MUST THROW ERROR! please use Delete["contract.class"]
  end
end


