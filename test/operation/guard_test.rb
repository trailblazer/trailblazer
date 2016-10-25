require "test_helper"

require "trailblazer/operation/policy" # FIXME.
module Trailblazer::Operation::Policy
  module Guard
    def self.included(includer)
      includer.extend DSL # ::policy
      includer.extend BuildPermission
      includer.| Evaluate, before: Trailblazer::Operation::Call
    end

    module BuildPermission
      # Simply return a proc that, when called, evaluates the Uber:::Value.
      def build_permission(callable, &block)
        value = Uber::Options::Value.new(callable || block)
        # call'ing the Uber value will run either proc or block.
        ->(*args) { { valid: value.(*args) } }
      end
    end
  end
end

class GuardTest < Minitest::Spec
  #---
  # with proc, evaluated in operation context.
  class Create < Trailblazer::Operation
    include Policy::Guard
    policy ->(params) { params[:pass] == self["params"][:pass] && params[:pass] }
    def process(*); self[:x] = true; end
  end

  it { Create.(pass: false)[:x].must_equal nil }
  it { Create.(pass: true)[:x].must_equal true }

  # with Callable, operation passed in.
  class Update < Create
    class MyGuard
      include Uber::Callable
      def call(operation, params); params[:pass] == operation["params"][:pass] && params[:pass] end
    end
    policy MyGuard.new
  end

  it { Update.(pass: false)[:x].must_equal nil }
  it { Update.(pass: true)[:x].must_equal true }
end
