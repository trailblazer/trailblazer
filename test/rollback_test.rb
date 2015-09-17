require "test_helper"

# TODO: rollback for composed operations: this is basically implemented already as every operation knows how to rollback.
# however, this has to be run for composed operations.
# we can also add Transaction and Lock for real uniqueness validators, etc.
#
# i am keen to try integrating https://github.com/collectiveidea/interactor organizers!
module Trailblazer::Operation::Rollback
  def run
    begin
      super
    rescue
      rollback!(@params, $!)
      [false, self]
    end
  end
end

class RollbackTest < MiniTest::Spec
  class ExceptionalOperation < Trailblazer::Operation
    include Rollback

    def process(params)
      @_params = params
      raise # something happens.
    end

    attr_reader :_params, :_rollback_args

    def rollback!(params, exception)
      @_rollback_args = [params, exception]
    end
  end

  module Comparable
    def ==(other)
      self.class == other.class
    end
  end

  it do
    op = ExceptionalOperation.("amazing")
    op._params.must_equal "amazing"

    op._rollback_args.must_equal ["amazing", RuntimeError.new.extend(Comparable)]
  end
end