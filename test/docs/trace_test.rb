require "test_helper"

class DocsTraceTest < Minitest::Spec
  Song = Struct.new(:id, :title)

  class MyContract < Reform::Form
    property :title
  end

  class Create < Trailblazer::Operation
    class Present < Trailblazer::Operation
      step Model( Song, :new )
      step Contract::Build( constant: MyContract )
    end

    step Nested( Present )
    step Contract::Validate( key: :song )
    step Contract::Persist()
    step :notify_band

    def notify_band(options, **)
      true
    end
  end

  let(:params)       { {} }
  let(:current_user) { Module }

  it do
    #:trace
    result = Create::Present.trace( params: params, current_user: current_user )
    puts result.wtf?

    # =>
    # |-- Start.default
    # |-- model.build
    # |-- contract.build
    # `-- End.success
    #:trace end

    result.wtf.gsub(/0x\w+/, "").must_equal %{|-- #<Trailblazer::Activity::Start semantic=:default>
|-- model.build
|-- contract.build
`-- #<Trailblazer::Operation::Railway::End::Success semantic=:success>}
  end

  it do
    #:trace-cpx
    result = Create.trace( params: params, current_user: current_user )
    puts result.wtf?

    # =>
    # |-- #<Trailblazer::Activity::Nested:0x000000031960d8>
    # |   |-- Start.default
    # |   |-- model.build
    # |   |-- contract.build
    # |   |-- End.success
    # |   `-- #<Trailblazer::Activity::Nested:0x000000031960d8>
    # |-- #<Trailblazer::Activity::Nested:0x0000000311f3e8>
    # |   |-- Start.default
    # |   |-- contract.default.params
    # |   |-- End.failure
    # |   `-- #<Trailblazer::Activity::Nested:0x0000000311f3e8>
    # `-- #<Trailblazer::Operation::Railway::End::Failure:0x00000003201fb8>
    #:trace-cpx end

#     result.wtf?.must_equal %{|-- Start.default
# |-- model.build
# |-- contract.build
# `-- End.success}
  end

    #   operation = ->(*args) { Create.__call__(*args) }

    # stack, _ = Trailblazer::Circuit::Trace.(
    #   operation,
    #   nil,
    #   options={ a_return: true },
    # )

    # puts output = Circuit::Trace::Present.tree(stack)
end
