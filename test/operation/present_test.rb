require "test_helper"

require "trailblazer/operation/present"

class Trailblazer::Operation
  module Present
    def self.included(includer)
      includer.extend Method
      includer.| Stop, before: Call
    end

    module Method
      def present(params={}, options={}, *args)
        call(params, options.merge("present.stop?" => true), *args)
      end
    end
  end

  # Stops the pipeline if "present.stop?" is set, which usually happens in Operation::present.
  Present::Stop = ->(input, options) { options[:skills]["present.stop?"] ? ::Pipetree::Stop : input }
end

class PresentTest < Minitest::Spec
  class Create < Trailblazer::Operation
    include Present

    include Model::Builder
    def model!(*); Object end

    def call(params)
      "#call run!"
    end
  end

  it do
    result = Create.present
    result["model"].must_equal Object
  end

  it { Create.().must_equal "#call run!" }
end
