require "trailblazer/operation/policy"

class Trailblazer::Operation
  module Policy
    def self.Guard(proc, name: :default, &block)
      Policy.step(Guard.build(proc), name: name)
    end

    module Guard
      def self.build(callable)
        value = Option::KW.(callable) # Operation::Option

        # this gets wrapped in a Operation::Result object.
        ->(input, options) { Result.new( !!value.(input, options), {} ) }
      end
    end # Guard
  end
end
