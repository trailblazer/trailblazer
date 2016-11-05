require "test_helper"

class PipedreamTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation

    class MyContract < Reform::Form
      property :title
    end

    module Model
      def self.[](model_class, action)
        Module.new do
          @a, @b = model_class, action
          def self.included(includer)
            includer.include Trailblazer::Operation::Model
            includer.model @a, @b
          end
          self
        end
      end
    end

    module Policy
      def self.[](proc)
        @a = proc
        def self.included(includer)
            includer.include Trailblazer::Operation::Policy::Guard # TODO: include step here "manually"
            includer.policy @a
          end
        self
      end
    end

    module Contract
      def self.[](contract_class)
        Module.new do
          @a = contract_class
          def self.included(includer)
            includer.include Trailblazer::Operation::Contract::Step # contract!
            includer["contract.default.class"]= @a
          end
          self
        end
      end
    end


    def self.*(name, mod)
      self.include mod
      self.> Trailblazer::Operation::Model::Build, before: "operation.result"
    end


    self.* "model",    Model[Song, :create]      # model!
    self.* "policy",   Policy[ ->(options){ options["user.current"] == ::Module } ]
    self.* "contract", Contract[MyContract]
  end

  it do
    # puts "@@@@@ #{Create.({}).inspect}"
    result = Create.({}, { "user.current" => Module })

    result["model"].inspect.must_equal %{#<struct PipedreamTest::Song title=nil>}
    result["result.policy"].success?.must_equal true
    result["contract"].class.superclass.must_equal Reform::Form


  end
end
