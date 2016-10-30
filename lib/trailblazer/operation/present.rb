class Trailblazer::Operation
  module Present
    def self.included(includer)
      includer.extend Method
      includer.& Stop, before: Call
    end

    module Method
      def present(params={}, options={}, *args)
        call(params, options.merge("present.stop?" => true), *args)
      end
    end
  end

  # Stops the pipeline if "present.stop?" is set, which usually happens in Operation::present.
  Present::Stop = ->(input, options) { ! options["present.stop?"] } # false returns Left.
end

# TODO: another stop for present without the contract!
