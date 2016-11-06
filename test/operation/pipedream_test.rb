require "test_helper"

class PipedreamTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation

    class MyContract < Reform::Form
      property :title
    end

    module Model
      def self.[](model_class, action)
        {
          include: [Trailblazer::Operation::Model::BuildMethods],
             step: Trailblazer::Operation::Model::Build,
             name: "model.build",
           skills: { "model.class" => model_class, "model.action" => action }
        }
      end
    end

    module Policy
      module Guard
        def self.[](proc)
          {
            # include: [],
               step: Trailblazer::Operation::Policy::Evaluate, # TODO: with different names?
               name: "policy.guard.evaluate",
             skills: { "policy.evaluator" => Trailblazer::Operation::Policy::Guard.build_permission(proc) }
          }
        end
      end
    end

    module Contract
      def self.[](contract_class)
        {
          include: [Trailblazer::Operation::Contract::Builder],
             step: Trailblazer::Operation::Contract::Build, # calls contract_for ATM.
             name: "contract.build",
           skills: { "contract.default.class" => contract_class }
        }
      end
    end

    # "import" mechanism.
    def self.*(name, cfg)
      cfg[:skills].each { |k,v| self[k] = v } # import skills.
      self.include *cfg[:include]               # include overridable instance logic.
      # append step right here.
      self.> cfg[:step], name: cfg[:name], before: "operation.result" # append_to: "setup" (group!)
    end


    self.* "model.build",    Model[Song, :create]      # model!
    self.* "policy",   Policy::Guard[ ->(options){ options["user.current"] == ::Module } ]
    self.* "contract", Contract[MyContract]
  end

  # TODO: test with contract constant (done). test with inline contract.

  it do
    # puts "@@@@@ #{Create.({}).inspect}"
    puts Create["pipetree"].inspect(style: :rows)
    result = Create.({}, { "user.current" => Module })

    result["model"].inspect.must_equal %{#<struct PipedreamTest::Song title=nil>}
    result["result.policy"].success?.must_equal true
    result["contract"].class.superclass.must_equal Reform::Form


  end
end
