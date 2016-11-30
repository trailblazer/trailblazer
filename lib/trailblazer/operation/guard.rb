require "trailblazer/operation/policy"
require "uber/option"

class Trailblazer::Operation
  module Policy
    module Guard
      extend Macro

      def self.import!(operation, import, user_proc, options={})
        name = options[:name] || :default

        # configure class level.
        operation[path = "policy.#{name}.eval"] = Guard.build(user_proc)

        # add step.
        import.(:&, Eval.new( name: name, path: path ),
          name: path
        )
      end

      def self.build(callable, &block)
        value = Uber::Option[callable || block]

        # call'ing the Uber::Option will run either proc or block.
        # this gets wrapped in a Operation::Result object.
        ->(options) { Result.new( !!value.(options), {} ) }
      end
    end # Guard
  end
end
