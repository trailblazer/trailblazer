require "test_helper"
require "reform/form/dry"
require "trailblazer/macro"
require "trailblazer/macro/contract"

class TrailblazerTest < Minitest::Spec
  Song = Struct.new(:title)


  class Create < Trailblazer::Operation
    class Form < Reform::Form
      include Reform::Form::Dry
      property :title

      validation do
        params do
          required(:title).filled(min_size?: 2)
        end
      end
    end

    step Model(Song, :new)
    step Contract::Build(constant: Form)
    step Contract::Validate()
    step Contract::Persist(method: :sync)
  end

  it do
    result = nil

    output, _ = capture_io do
      result = Create.wtf?(params: {title: "Dead and Gone"})
    end

    assert_equal output, %(TrailblazerTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel.build\e[0m
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[32mcontract.default.call\e[0m
|   `-- End.success
|-- \e[32mpersist.save\e[0m
`-- End.success
)
    assert_equal result.success?, true
    assert_equal result[:model].to_h, {:title=>"Dead and Gone"}

  # invalid!
      result = Create.wtf?(params: {})
    output, _ = capture_io do
      result = Create.wtf?(params: {})
    end

    assert_equal output, %(TrailblazerTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel.build\e[0m
|-- \e[32mcontract.build\e[0m
|-- contract.default.validate
|   |-- \e[32mStart.default\e[0m
|   |-- \e[32mcontract.default.params_extract\e[0m
|   |-- \e[33mcontract.default.call\e[0m
|   `-- End.failure
`-- End.failure
)

    assert_equal result.success?, false
    assert_equal result[:mode].to_h, {}
  end
end

# Song = Struct.new(:title)
# class Song
#   module Operation
#     class Create < Trailblazer::Operation
#       step :create_model
#       step :validate
#       fail :handle_errors
#       step :notify

#       def create_model(ctx, **)
#         # do whatever you feel like.
#         ctx[:model] = Song.new
#       end

#       def validate(ctx, params:, **)
#         # ..
#       end

#       def handle_errors(ctx, **)
#         true
#       end
#     end

#   end
# end

# Song::Operation::Create.wtf?(params: {})
