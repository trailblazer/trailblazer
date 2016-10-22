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
      true
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
      result = InitPipetree.(params, read: self, write: self)

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



    ModelBuilderBuilder = ->(input, options) { options[:model] = ModelBuilder.new(options[:read]).(input); input }
    # this is to be able to use BuildModel. i really don't know if we actually need to do that.
    # what if people want to override #model! for example?
    class ModelBuilder
      def initialize(skills)
        @delegator = skills
      end

      extend Uber::Delegates
      delegates :@delegator, :[]=, :[]

      include Trailblazer::Operation::Model::BuildModel # #instantiate_model and so on.

      def call(params)
        model!(params)
      end
    end

    AssignModel = ->(input, options) { options[:write]["model"]   = options[:model] }
    AssignPolicy = ->(input, options) { options[:write]["policy"] = options[:policy] }


    # "current_user" is now a skill dependency, not a params option anymore.
    PolicyEvaluate = ->(input, options) {
      # TODO: assign policy
      options[:policy] = options[:read]["policy.evaluator"].(options["current_user"], options[:read]["model"]) { return Pipetree::Stop }; input
    }

    InitPipetree = Pipetree[
      SetupParams,
      ModelBuilderBuilder, AssignModel,
      PolicyEvaluate,
    ]
  end

  it { Create.({song: { title: "311" }}).class.must_equal Song }


  #---
  # External and Resolver, done right.
  class Update < Trailblazer::Operation
    include Model
    extend Policy::DSL

    model Song
    policy Auth, :create?

    def self.build_operation(params, *args)
      # FIXME: other skills from other containers are not available here.

      pipe = Pipetree[
        Create::SetupParams,
        Create::ModelBuilderBuilder, Create::AssignModel,
        Create::PolicyEvaluate,
        Create::AssignPolicy,
      ]


      pipe.(params, { read: self, write: options={} })

      new(params, options)
    end

    def call(*)
      self
    end
  end

  it {
    op = Update.({})

    op["policy"].inspect.must_match /Auth/
    op["model"].class.must_equal Song

  }

end
