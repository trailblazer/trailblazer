require "test_helper"

class DocsWrapTest < Minitest::Spec
  module Memo
  end

  module Methods
    def find_model(ctx, seq:, **)
      seq << :find_model
    end

    def update(ctx, seq:, **)
      seq << :update
    end

    def notify(ctx, seq:, **)
      seq << :notify
    end

    def rehash(ctx, seq:, rehash_raise:false, **)
      seq << :rehash
      raise if rehash_raise
      true
    end

    def log_error(ctx, seq:, **)
      seq << :log_error
    end
  end

  class Memo::Create < Trailblazer::Operation
    class HandleUnsafeProcess
      def self.call(ctx, *, &block)
        begin
          yield # calls the wrapped steps
        rescue
          [ Trailblazer::Operation::Railway.fail!, [ctx, {}] ]
        end
      end
    end

    step :find_model
    step Wrap( HandleUnsafeProcess ) {
      step :update
      step :rehash
    }
    step :notify
    fail :log_error

    #~methods
    include Methods
    #~methods end
  end

  describe "callable wrap" do
    it { Memo::Create.( { seq: [] } ).inspect(:seq).must_equal %{<Result:true [[:find_model, :update, :rehash, :notify]] >} }
    it { Memo::Create.( { seq: [], rehash_raise: true } ).inspect(:seq).must_equal %{<Result:false [[:find_model, :update, :rehash, :log_error]] >} }
  end

  class WrapGoesIntoFailFastTest < Minitest::Spec
    Memo = Module.new

    class Memo::Create < Trailblazer::Operation
      class HandleUnsafeProcess
        def self.call(ctx, *, &block)
          begin
            yield # calls the wrapped steps
          rescue
            [ Trailblazer::Operation::Railway.fail!, [ctx, {}] ]
          end
        end
      end

      step :find_model
      step Wrap( HandleUnsafeProcess ) {
        step :update
        step :rehash
      }, fail_fast: true
      step :notify
      fail :log_error

      #~methods
      include DocsWrapTest::Methods
      #~methods end
    end

    it { Memo::Create.( { seq: [] } ).inspect(:seq).must_equal %{<Result:true [[:find_model, :update, :rehash, :notify]] >} }
    it { Memo::Create.( { seq: [], rehash_raise: true } ).inspect(:seq).must_equal %{<Result:false [[:find_model, :update, :rehash]] >} }
  end

  class WrapGoesIntoFailFastViaFastTrackTest < Minitest::Spec
    Memo = Module.new

    class Memo::Create < Trailblazer::Operation
      class HandleUnsafeProcess
        def self.call(ctx, *, &block)
          begin
            yield # calls the wrapped steps
          rescue
            [ Trailblazer::Operation::Railway.fail_fast!, [ctx, {}] ]
          end
        end
      end

      step :find_model
      step Wrap( HandleUnsafeProcess ) {
        step :update
        step :rehash
      }, fast_track: true
      step :notify
      fail :log_error

      #~methods
      include DocsWrapTest::Methods
      #~methods end
    end

    it { Memo::Create.( { seq: [] } ).inspect(:seq).must_equal %{<Result:true [[:find_model, :update, :rehash, :notify]] >} }
    it { Memo::Create.( { seq: [], rehash_raise: true } ).inspect(:seq).must_equal %{<Result:false [[:find_model, :update, :rehash]] >} }
  end

  class WrapGoesIntoPassFromRescueTest < Minitest::Spec
    Memo = Module.new

    class Memo::Create < Trailblazer::Operation
      class HandleUnsafeProcess
        def self.call(ctx, *, &block)
          begin
            yield # calls the wrapped steps
          rescue
            [ Trailblazer::Operation::Railway.pass!, [ctx, {}] ]
          end
        end
      end

      step :find_model
      step Wrap( HandleUnsafeProcess ) {
        step :update
        step :rehash
      }
      step :notify
      fail :log_error

      #~methods
      include DocsWrapTest::Methods
      #~methods end
    end

    it { Memo::Create.( { seq: [] } ).inspect(:seq).must_equal %{<Result:true [[:find_model, :update, :rehash, :notify]] >} }
    it { Memo::Create.( { seq: [], rehash_raise: true } ).inspect(:seq).must_equal %{<Result:true [[:find_model, :update, :rehash, :notify]] >} }
  end


  Song = Struct.new(:id, :title) do
    def self.find(id)
      id.nil? ? raise : new(id)
    end
  end


# it allows returning legacy true/false
  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end

    step Wrap( ->(options, *, &block) {
      begin
        block.call
      rescue => exception
        options["result.model.find"] = "argh! because #{exception.class}"
        return false
      end
      true
      }) {
      step Model( Song, :find )
      step Contract::Build( constant: MyContract )
    }
    step Contract::Validate()
    step Contract::Persist( method: :sync )
  end

  it { Create.( params: {id: 1, title: "Prodigal Son"} )["contract.default"].model.inspect.must_equal %{#<struct DocsWrapTest::Song id=1, title="Prodigal Son">} }
  it { Create.( params: {id: nil }).inspect("result.model.find").must_equal %{<Result:false [\"argh! because RuntimeError\"] >} }

  #-
  # Wrap return
  class WrapReturnTest < Minitest::Spec
    class Create < Trailblazer::Operation
      step Wrap( ->(options, *, &block) { options["yield?"] ? block.call : false }) {
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
    step Wrap( ->(*, &block) { Sequel.transaction do block.call end } ) {
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

    it { Create.( params: {title: "Pie"} ).inspect(:model, "x", "err").must_equal %{<Result:true [#<struct DocsWrapTest::Song id=nil, title=\"Pie\">, nil, nil] >} }
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

    it { Create.( params: {title: "Pie"} ).inspect(:model, "x", "err").must_equal %{<Result:true [#<struct DocsWrapTest::Song id=nil, title=\"Pie\">, nil, nil] >} }
  end

  class WrapWithMethodTest < Minitest::Spec
    class Create < Trailblazer::Operation
      step Model( Song, :new )
      step Wrap( ->(options, *, &block) { block.call } ) {
        step :check_model!

      }

      def check_model!(options, model:, **)
        options["x"] = model
      end
    end

    it { Create.(params: {}) }
  end
end

