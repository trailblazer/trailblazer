require 'test_helper'

class OperationCallableTest < MiniTest::Spec
  class AnotherCreate < Trailblazer::Operation
    step :proccess

    def proccess(options, params:, **)
      options['result'] = params
    end
  end

  class Create < Trailblazer::Operation
    step Callable(AnotherCreate, result: 'result.test')
  end

  it do
    result = Create.({is_ok: true}, 'my.options' => 'ok')
    result['result.test'].must_equal(is_ok: true)
  end
end
