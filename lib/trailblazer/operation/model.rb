class Trailblazer::Operation
  def self.Model(model_class, action=nil)
    step = Model.for(model_class, action)

    # step = Pipetree::Step.new(step, "model.class" => model_class, "model.action" => action)
    task           = Railway::TaskBuilder.( step )
    runner_options = {
      alteration: ->(wrap_circuit) do
        Trailblazer::Circuit::Activity::Before( wrap_circuit,
          Trailblazer::Circuit::Wrap::Call,
          Trailblazer::Operation::Railway::Inject( "model.class" => model_class, "model.action" => action ),
          direction: Trailblazer::Circuit::Right
        )
      end
    }

    [ task, { name: "model.build" }, runner_options ]
  end

  module Model
    def self.for(model_class, action)
      builder = Model::Builder.new

      ->(options, **) do
        options["model"] = model = builder.(options, options["params"])

        options["result.model"] = result = Result.new(!model.nil?, {})

        result.success?
      end
    end

    class Builder
      def call(options, params)
        deprecate_update!(options)
        action      = options["model.action"] || :new
        model_class = options["model.class"]

        send("#{action}!", model_class, params)
      end

      def new!(model_class, params)
        model_class.new
      end

      def find!(model_class, params)
        model_class.find(params[:id])
      end

      # Doesn't throw an exception and will return false to divert to Left.
      def find_by!(model_class, params)
        model_class.find_by(id: params[:id])
      end

    private
      def deprecate_update!(options) # TODO: remove in 2.1.
        return unless options["model.action"] == :update
        options["model.action"] = :find
        warn "[Trailblazer] Model( .., :update ) is deprecated, please use :find or :find_by."
      end
    end
  end
end
