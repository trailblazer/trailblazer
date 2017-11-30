class Trailblazer::Operation
  def self.Model(model_class, action=nil)
    # step = Pipetree::Step.new(step, "model.class" => model_class, "model.action" => action)

    task = Railway::TaskBuilder.( Model.new )

    runner_options = {
      merge: Wrap::Inject::Defaults(
        "model.class"  => model_class,
        "model.action" => action
      )
    }

    { task: task, id: "model.build", runner_options: runner_options }
  end

  class Model
    def call(options, params:,  **)
      builder = Model::Builder.new

      options["model"] = model = builder.(options, params)

      options["result.model"] = result = Result.new(!model.nil?, {})

      result.success?
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
