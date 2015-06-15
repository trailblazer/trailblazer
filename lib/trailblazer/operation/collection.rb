module Trailblazer::Operation::Collection
  # Collection does not produce a contract.
  def present(*params)
    setup!(*params)
    self
  end
end
