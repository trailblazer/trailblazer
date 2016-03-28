require "test_helper"
require "trailblazer/operation/dispatch"


class DslCallbackTest < MiniTest::Spec
  module SongProcess
    def process(params)
      contract(OpenStruct.new).validate(params)
      dispatch!
    end

    def _invocations
      @_invocations ||= []
    end

    def self.included(includer)
      includer.contract do
        property :title
      end
    end
  end

  describe "inheritance across operations" do
    class Operation < Trailblazer::Operation
      include Dispatch
      include SongProcess

      callback do
        on_change :default!
      end

      class Admin < self
        callback do
          on_change :admin_default!
        end

        callback(:after_save) { on_change :after_save! }

        def admin_default!(*); _invocations << :admin_default!; end
        def after_save!(*);    _invocations << :after_save!; end

        def process(*)
          super
          dispatch!(:after_save)
        end
      end

      def default!(*); _invocations << :default!; end
    end

    it { Operation.({"title"=> "Love-less"})._invocations.must_equal([:default!]) }
    it { Operation::Admin.({"title"=> "Love-less"})._invocations.must_equal([:default!, :admin_default!, :after_save!]) }
  end

  describe "Op.callback" do
    it { Operation.callback(:default).must_equal Operation.callbacks[:default][:group] }
  end

  describe "Op.callback :after_save, AfterSaveCallback" do
    class AfterSaveCallback < Disposable::Callback::Group
      on_change :after_save!

      def after_save!(twin, options)
        options[:operation]._invocations << :after_save!
      end
    end

    class OpWithExternalCallback < Trailblazer::Operation
      include Dispatch
      include SongProcess
      callback :after_save, AfterSaveCallback

      def process(params)
        contract(OpenStruct.new).validate(params)
        dispatch!(:after_save)
      end
    end

    it { OpWithExternalCallback.("title"=>"Thunder Rising")._invocations.must_equal([:after_save!]) }
  end

  describe "Op.callback :after_save, AfterSaveCallback do .. end" do
    class DefaultCallback < Disposable::Callback::Group
      on_change :default!

      def default!(twin, options)
        options[:operation]._invocations << :default!
      end
    end

    class OpUsingCallback < Trailblazer::Operation
      include Dispatch
      include SongProcess
      callback :default, DefaultCallback
    end

    class OpExtendingCallback < Trailblazer::Operation
      include Dispatch
      include SongProcess
      callback :default, DefaultCallback do
        on_change :after_save!

        def default!(twin, options)
          options[:operation]._invocations << :extended_default!
        end

        def after_save!(twin, options)
          options[:operation]._invocations << :after_save!
        end
      end
    end

    # this operation copies DefaultCallback and shouldn't run #after_save!.
    it { OpUsingCallback.(title: "Thunder Rising")._invocations.must_equal([:default!]) }
    # this operation copies DefaultCallback, extends it and runs #after_save!.
    it { OpExtendingCallback.(title: "Thunder Rising")._invocations.must_equal([:extended_default!, :after_save!]) }
  end
end
