require "trailblazer/operation/policy"
require "uber/option"

class Trailblazer::Operation
  module Policy
    module Guard
      def self.import!(operation, import, user_proc, options={}, insert_options={})
        Policy.add!(operation, import, options, insert_options) { Guard.build(user_proc) }
      end

      def self.override!(*args, options)
        Guard.import!(*args, options, replace: options[:path])
      end

      def self.build(callable)
        value = Uber::Option[callable]

        # call'ing the Uber::Option will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(options) { Result.new( !!value.(options), {} ) }
      end
    end # Guard

    def self.Guard(proc, name: :default, &block)
      options = {
        name:  name,
        path: "policy.#{name}.eval",
      }

      [Guard, [proc, options], block]
    end
  end
end
