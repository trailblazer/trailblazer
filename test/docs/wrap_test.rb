require "test_helper"

class RescueTest < Minitest::Spec
  Song = Struct.new(:id, :title) do
    def self.find(id)
      raise if id.nil?
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

    self.| Wrap ->(pipe, operation, options) {
      begin
        pipe.(operation, options)
      rescue => exception
        options["result.model.find"] = "argh! because #{exception.class}"
        false
      end } { |pipe|
      pipe.| Model[ Song, :find ]
      pipe.| Contract::Build[ constant: MyContract ]
    }
    self.| Contract::Validate[]
    self.| Persist[ method: :sync ]
  end

  it { Create.( id: 1, title: "Prodigal Son" )["contract.default"].model.inspect.must_equal %{#<struct RescueTest::Song id=1, title="Prodigal Son">} }
  it { Create.( id: nil ).inspect("result.model.find").must_equal %{<Result:false [\"argh! because RuntimeError\"] >} }
end



# class Create < Trailblazer::Operation
#   self.| Rescue[->(exception, options) { handle_the_exception }] do |s|
#     s.| Model[]
#     s.| Contract::Build[]
#   end
# end
