# NOTE: this might get removed in TRB 2.1.
module Trailblazer::Operation::Contract
  module Raise
    def validate(*)
      super.tap do |res|
        raise!(contract) unless res
      end
    end

    def raise!(contract)
      raise ::Trailblazer::Operation::InvalidContract.new(contract.errors.to_s)
    end
  end
end

class Trailblazer::Operation::InvalidContract < RuntimeError
end
