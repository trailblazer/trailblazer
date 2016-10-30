class Trailblazer::Operation
  module Params
    def self.included(includer)
      includer.> Replace, after: New
    end
  end

  # Returned object will replace "params". Original is saved in "params.original".
  Params::Replace = ->(input, options) {
    options["params.original"] = original = options["params"]
     options["params"] = input.params!(original)
   }
end
