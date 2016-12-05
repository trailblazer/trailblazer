require "test_helper"

class RescueTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      new(id)
    end
  end

  # class Create < Trailblazer::Operation
  #   self.> ->(options) { options["x"] = true }

  # #   self.> ->(options) {
  # #     begin
  # #       wasauchimmer.(input, options) }
  # #     rescue

  # #     end
  # #   # self.| Rescue[ Model[ Song, :find ] ]
  # end

  # it { Create.() }

  class Create < Trailblazer::Operation
    class MyContract < Reform::Form
      property :title
    end
    # Transaction
    #   extend U
    # end

    self.| Wrap ->(pipe, input, options) { pipe.(input, options) } { |s|
      s.| Model[ Song, :find ]
      s.| Contract::Build[ constant: MyContract ]
    }
    self.| Contract::Validate[]
    self.| Persist[ method: :sync ]
  end

  it { Create.( title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct RescueTest::Song id=nil, title="Prodigal Son">} }
end



# class Create < Trailblazer::Operation
#   self.| Rescue[->(exception, options) { handle_the_exception }] do |s|
#     s.| Model[]
#     s.| Contract::Build[]
#   end
# end
