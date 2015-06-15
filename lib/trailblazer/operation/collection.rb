module Trailblazer::Operation::Collection
  # Collection does not produce a contract.
  attr_reader :model

  def present(*params)
    setup!(*params)
    self
  end
end
