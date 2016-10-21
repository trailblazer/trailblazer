require "test_helper"
require "pipetree"

class PipetreeTest < Minitest::Spec
  module Setup
    # Params ->(result, options) { snippet }
    # Model ->(result, options) { snippet }
  end

  Song = Struct.new(:title)
# the idea is, leave the configuration in the operation. the implementation can be done on the op, or in a dedicated object that *reads* config from the op.

  class Auth
    def initialize(*)

    end

    def create?
    end
  end

  class Create < Trailblazer::Operation
    include Model
    model Song, :create

    require "trailblazer/operation/policy"
    extend Policy::DSL
    policy Auth, :create?

    def initialize(params, *)
      super

      # was setup!
      result = Pipetree[
        SetupParams,
        ModelBuilder.new(self), AssignModel,
        PolicyEvaluate,
      ].
        (params, self)

      puts "@@@@@ #{result.inspect}"
    end

    def call(params)
      super
      self["model"]
    end

    def process(params)
      # validate(params)
      #   success
      #     callbacks
    end

    # unwrap params.
    SetupParams = ->(input, options) { input[:song] }



    class ModelBuilder
      def initialize(options)
        @delegator = options
      end

      extend Uber::Delegates
      delegates :@delegator, :[]=, :[]

      include Trailblazer::Operation::Model::BuildModel # #instantiate_model and so on.

      def call(params, options)
        model!(params)
      end
    end

    AssignModel = ->(input, options) { options["model"] = input }


    # "current_user" is now a skill dependency, not a params option anymore.
    PolicyEvaluate = ->(input, options) {
      # TODO: assign policy
      options["policy.evaluator"].(options["current_user"], options["model"]) { return Pipetree::Stop }; input
    }
  end

  it { Create.({song: { title: "311" }}).class.must_equal Song }
end
