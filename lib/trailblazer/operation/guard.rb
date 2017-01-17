require "trailblazer/operation/policy"
require "uber/option"

class Trailblazer::Operation
  module Policy
    def self.Guard(proc, name: :default, &block)
      Policy.step(Guard.build(proc), name: name)
    end

    module Guard
      def self.build(callable)
        value = Uber::Option[callable]

        # call'ing the Uber::Option will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(options) { Result.new( !!value.(options), {} ) }
      end
    end # Guard
  end
end
