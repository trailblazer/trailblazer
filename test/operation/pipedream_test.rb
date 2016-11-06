require "test_helper"

class PipedreamTest < Minitest::Spec
  Song = Struct.new(:title)

  class Create < Trailblazer::Operation

    class MyContract < Reform::Form
      property :title
    end

    # "import" mechanism.
    def self.step(operator, name, cfg=nil)
      cfg ||= name #if cfg.nil?

      cfg[:skills].each { |k,v| self[k] = v } # import skills.
      self.include *cfg[:include]               # include overridable instance logic.
      # append step right here.
      self.send operator, cfg[:step], name: cfg[:name], before: "operation.result" # append_to: "setup" (group!)
    end

    # design principles:
    # * include as less code as possible into the op class.
    # * make the flow super explicit without making it cryptic (only 3 new operators)
    # * avoid including DSL modules in favor of passing those configurations directly to the "step".

    module DSLOperators
      def >(name, cfg=nil)
        super *import!(name, cfg)
      end

      def <(name, cfg=nil)
        super *import!(name, cfg)
      end

    # :private:
      def import!(name, config=nil)
        config ||= name

        config[:skills].each { |k,v| self[k] = v } # import skills.
        include *config[:include]                  # include overridable instance logic.

        [ config[:step], name: config[:name], before: "operation.result" ]
      end
    end
    extend DSLOperators

    self.> Model[Song, :create]      # model!)
    self.> Policy::Guard[ ->(options){ options["user.current"] == ::Module } ]
    self.> Contract[MyContract]
    self.< Contract[MyContract]
    # ok Model[Song, :create]      # model!)
    # ok Policy::Guard[ ->(options){ options["user.current"] == ::Module } ]
    # ok Contract[MyContract]
    # fail Contract[MyContract]
    # self.|> "contract"

  end

  # TODO: test with contract constant (done).
  #       test with inline contract.
  #       test with override contract!.

  it do
    # puts "@@@@@ #{Create.({}).inspect}"
    puts Create["pipetree"].inspect(style: :rows)
    result = Create.({}, { "user.current" => Module })

    result["model"].inspect.must_equal %{#<struct PipedreamTest::Song title=nil>}
    result["result.policy"].success?.must_equal true
    result["contract"].class.superclass.must_equal Reform::Form


  end
end
