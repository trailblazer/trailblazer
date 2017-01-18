require "test_helper"

class WrapTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      id.nil? ? raise : new(id)
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

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct WrapTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("result.model.find").must_equal %{<Result:false [\"argh! because RuntimeError\"] >} }

  #-
  # Wrap return
  class WrapReturnTest < Minitest::Spec
    class Create < Trailblazer::Operation
      step Wrap ->(options, *, &block) { options["yield?"] ? block.call : false } {
        step ->(options) { options["x"] = true }
        success :noop!
        # ...
      }

      def noop!(options)
      end
    end

    it { Create.().inspect("x").must_equal %{<Result:false [nil] >} }
    # returns falsey means deviate to left.
    it { Create.({}, "yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
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
        step ->(options) { options["x"] = true }
        # ...
      }
    end

    it { Create.().inspect("x").must_equal %{<Result:false [nil] >} }
    # returns falsey means deviate to left.
    it { Create.({}, "yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }
  end

  #-
  # arguments for Wrap
  class Update < Trailblazer::Operation
    step Wrap ->(options, operation, pipe, &block) { operation["yield?"] ? block.call : false } {
      step ->(options) { options["x"] = true }
    }
  end

  it { Update.().inspect("x").must_equal %{<Result:false [nil] >} }
  it { Update.({}, "yield?" => true).inspect("x").must_equal %{<Result:true [true] >} }

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

    def notify!(options)
      MyNotifier.mail
    end
    #~wrap-only end
  end
  #:sequel-transaction end

    it { Create.( title: "Pie" ).inspect("model", "x", "err").must_equal %{<Result:true [#<struct WrapTest::Song id=nil, title=\"Pie\">, nil, nil] >} }
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
    extend Uber::Callable

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

    def notify!(options)
      MyNotifier.mail # send emails, because success...
    end
    #~wrap-onlyy end
  end
  #:sequel-transaction-callable end

    it { Create.( title: "Pie" ).inspect("model", "x", "err").must_equal %{<Result:true [#<struct WrapTest::Song id=nil, title=\"Pie\">, nil, nil] >} }
  end
end

