class Trailblazer::Operation
  module Policy
    def self.Guard(proc, name: :default, &block)
      Policy.step( Guard.build(proc), name: name )
    end

    module Guard
      def self.build(callable)
        value = Trailblazer::Circuit::Task::Args::KW(callable)

        # this gets wrapped in a Operation::Result object.
        ->(direction, options, flow_options) { Result.new( !!value.(direction, options, flow_options), {} ) }
      end
    end # Guard
  end
end
