require "test_helper"

class DslCallbackTest < MiniTest::Spec
  module SongProcess
    def _invocations
      self["x"] ||= []
    end

    def self.included(includer)
      includer.extend Trailblazer::Operation::Contract::DSL
      includer.contract do
        property :title
      end
      includer.| Trailblazer::Operation::Model[OpenStruct, :new]
      includer.| Trailblazer::Operation::Contract::Build[includer["contract.default.class"]]
      includer.| Trailblazer::Operation::Contract::Validate[]
      includer.| Trailblazer::Operation::Callback[:default]
    end
  end

  describe "inheritance across operations" do
    class Operation < Trailblazer::Operation
      extend Callback::DSL
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

        step Trailblazer::Operation::Callback[:after_save]
      end

      def default!(*); _invocations << :default!; end
    end

    it { Operation.({"title"=> "Love-less"})["x"].must_equal([:default!]) }
    it { Operation::Admin.({"title"=> "Love-less"})["x"].must_equal([:default!, :admin_default!, :after_save!]) }
  end

  describe "Op.callback :after_save, AfterSaveCallback" do
    class AfterSaveCallback < Disposable::Callback::Group
      on_change :after_save!

      def after_save!(twin, options)
        options[:operation]._invocations << :after_save!
      end
    end

    class OpWithExternalCallback < Trailblazer::Operation
      include SongProcess
      extend Callback::DSL
      callback :after_save, AfterSaveCallback

      step Callback[:after_save]
    end

    it { OpWithExternalCallback.("title"=>"Thunder Rising").must_equal([:after_save!]) }
  end

  describe "Op.callback :after_save, AfterSaveCallback do .. end" do
    class DefaultCallback < Disposable::Callback::Group
      on_change :default!

      def default!(twin, options)
        options[:operation]._invocations << :default!
      end
    end

    class OpUsingCallback < Trailblazer::Operation
      extend Callback::DSL
      include SongProcess
      callback :default, DefaultCallback
    end

    class OpExtendingCallback < Trailblazer::Operation
      extend Callback::DSL
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
    it { OpUsingCallback.(title: "Thunder Rising")["x"].must_equal([:default!]) }
    # this operation copies DefaultCallback, extends it and runs #after_save!.
    it { OpExtendingCallback.(title: "Thunder Rising")["x"].must_equal([:extended_default!, :after_save!]) }
  end
end
