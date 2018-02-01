require "test_helper"

# TODO: consume End signal from wrapped

class WrapTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      id.nil? ? raise : new(id)
    end
  end

  class DirectWiringTest < Minitest::Spec
    class Create < Trailblazer::Operation
      class MyContract < Reform::Form
        property :title
      end

      step( Wrap( ->(options, *args, &block) {
        begin
          block.call
        rescue => exception
          options["result.model.find"] = "argh! because #{exception.class}"
          [ Railway.fail_fast!, options, *args ]
        end }) {
        step ->(options, **) { options["x"] = true }
        step Model( Song, :find )
        step Contract::Build( constant: MyContract )
      }.merge(fast_track: true))
      step Contract::Validate()
      step Contract::Persist( method: :sync )
    end

    it { Create.( params: {id: 1, title: "Prodigal Son"} ).inspect("x", :model).must_equal %{<Result:true [true, #<struct WrapTest::Song id=1, title=\"Prodigal Son\">] >} }

    it "goes directly from Wrap to End.fail_fast" do
      Create.(params: {}).inspect("x", :model, "result.model.find").must_equal %{<Result:false [true, nil, "argh! because RuntimeError"] >}
    end
  end

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Wrap ->(options, *, &block) {
      begin
        block.call
      rescue => exception
        options["result.model.find"] = "argh! because #{exception.class}"
        false
      end } {
      step Model( Song, :find )
      step Contract::Build( constant: MyContract )
    }
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end

  it { Create.( params: {id: 1, title: "Prodigal Son"} )["contract.default"].model.inspect.must_equal %{#<struct WrapTest::Song id=1, title="Prodigal Son">} }
  it { Create.( params: {id: nil }).inspect("result.model.find").must_equal %{<Result:false [\"argh! because RuntimeError\"] >} }

  #-
  # Wrap return
  class WrapReturnTest < Minitest::Spec
    class Create < Trailblazer::Operation
      step Wrap ->(options, *, &block) { options["yield?"] ? block.call : false } {
        step ->(options, **) { options["x"] = true }
        success :noop!
        # ...
      }

      def noop!(options, **)
      end
    end

    it { Create.(params: {}).inspect("x").must_equal %{<Result:false [nil] >} }
    # returns falsey means deviate to left.
    it { Create.("yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
  end

  class WrapWithCallableTest < Minitest::Spec
    class MyWrapper
      extend Uber::Callable

      def self.call(options, *, &block)
        options["yield?"] ? yield : false
      end
    end

    class Create < Trailblazer::Operation
      step Wrap( MyWrapper ) {
        step ->(options, **) { options["x"] = true }
        # ...
      }
    end

    it { Create.(params: {}).inspect("x").must_equal %{<Result:false [nil] >} }
    # returns falsey means deviate to left.
    it { Create.("yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
  end

  class WrapExampleProcTest < Minitest::Spec
    module Sequel
      def self.transaction
        yield
      end
    end

    module MyNotifier
      def self.mail; true; end
    end

  #:sequel-transaction
  class Create < Trailblazer::Operation
    #~wrap-only
    class MyContract < Reform::Form
      property :title
    end

    #~wrap-only end
    step Wrap ->(*, &block) { Sequel.transaction do block.call end } {
      step Model( Song, :new )
      #~wrap-only
      step Contract::Build( constant: MyContract )
      step Contract::Validate( )
      step Contract::Persist( method: :sync )
      #~wrap-only end
    }
    failure :error! # handle all kinds of errors.
    #~wrap-only
    step :notify!

    def error!(options)
      # handle errors after the wrap
    end

    def notify!(options, **)
      MyNotifier.mail
    end
    #~wrap-only end
  end
  #:sequel-transaction end

    it { Create.( params: {title: "Pie"} ).inspect(:model, "x", "err").must_equal %{<Result:true [#<struct WrapTest::Song id=nil, title=\"Pie\">, nil, nil] >} }
  end

  class WrapExampleCallableTest < Minitest::Spec
    module Sequel
      def self.transaction
        yield
      end
    end

    module MyNotifier
      def self.mail; true; end
    end

  #:callable-t
  class MyTransaction
    def self.call(options, *)
      Sequel.transaction { yield } # yield runs the nested pipe.
      # return value decides about left or right track!
    end
  end
  #:callable-t end
  #:sequel-transaction-callable
  class Create < Trailblazer::Operation
    #~wrap-onlyy
    class MyContract < Reform::Form
      property :title
    end

    #~wrap-onlyy end
    step Wrap( MyTransaction ) {
      step Model( Song, :new )
      #~wrap-onlyy
      step Contract::Build( constant: MyContract )
      step Contract::Validate( )
      step Contract::Persist( method: :sync )
      #~wrap-onlyy end
    }
    failure :error! # handle all kinds of errors.
    #~wrap-onlyy
    step :notify!

    def error!(options)
      # handle errors after the wrap
    end

    def notify!(options, **)
      MyNotifier.mail # send emails, because success...
    end
    #~wrap-onlyy end
  end
  #:sequel-transaction-callable end

    it { Create.( params: {title: "Pie"} ).inspect(:model, "x", "err").must_equal %{<Result:true [#<struct WrapTest::Song id=nil, title=\"Pie\">, nil, nil] >} }
  end

  class WrapWithMethodTest < Minitest::Spec
    class Create < Trailblazer::Operation
      step Model( Song, :new )
      step Wrap ->(options, *, &block) { block.call } {
        step :check_model!

      }

      def check_model!(options, model:, **)
        options["x"] = model
      end
    end

    it { Create.(params: {}) }
  end
end

