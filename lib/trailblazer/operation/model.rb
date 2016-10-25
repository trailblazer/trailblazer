class Trailblazer::Operation
  module Model
    def self.included(includer)
      includer.extend DSL
      includer.| Build, after: New
    end

    module DSL
      def model(name, action=nil)
        heritage.record(:model, name, action)

        self["model.class"] = name
        action(action) if action # coolest line ever.
      end

      def action(name)
        heritage.record(:action, name)

        self["model.action"] = name
      end
    end

  # Methods to create the model according to class configuration and params.
    module BuildMethods
      def model_class
        self["model.class"] or raise "[Trailblazer] You didn't call Operation::model."
      end

      def action_name
        self["model.action"] or :create
      end

      def model!(params)
        instantiate_model(params)
      end

      def instantiate_model(params)
        send("#{action_name}_model", params)
      end

      def create_model(params)
        model_class.new
      end

      def update_model(params)
        model_class.find(params[:id])
      end

      alias_method :find_model, :update_model
    end

    # this is to be able to use BuildModel. i really don't know if we actually need to do that.
    # what if people want to override #model! for example?
    class Builder
      def initialize(skills)
        @delegator = skills
      end

      extend Uber::Delegates
      delegates :@delegator, :[]

      include BuildMethods # #instantiate_model and so on.
      alias_method :call, :model!
    end
  end

  Model::Build  = ->(input, options) { options[:skills]["model"] = Model::Builder.new(options[:skills]).(options[:skills]["params"]); input }
end
