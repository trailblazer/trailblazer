require "trailblazer/operation/policy"
require "uber/option"

class Trailblazer::Operation
  module Policy
    module Guard
      def self.import!(operation, import, user_proc, options={})
        Policy.add!(operation, import, options) { Guard.build(user_proc) }
      end

      def self.build(callable)
        value = Uber::Option[callable]

        # call'ing the Uber::Option will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(options) { Result.new( !!value.(options), {} ) }
      end
    end # Guard

    def self.Guard(*args, &block)
      [ Guard, args, block ]
    end
  end
end
