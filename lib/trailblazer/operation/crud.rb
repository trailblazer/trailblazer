module Trailblazer
  class Operation
    # The CRUD module will automatically create/find models for the configured +action+.
    # It adds a public  +Operation#model+ reader to access the model (after performing).
    module CRUD
      attr_reader :model

      def self.included(base)
        base.extend Uber::InheritableAttr
        base.inheritable_attr :config
        base.config = {}

        base.extend ClassMethods
      end

      module ClassMethods
        def model(name, action=nil)
          self.config[:model] = name
          action(action) if action # coolest line ever.
        end

        def action(name)
          self.config[:action] = name
        end

        def action_name # considered private.
          self.config[:action] or :create
        end

        def model_name # considered private.
          self.config[:model] or raise "[Trailblazer] You didn't call Operation::model." # TODO: infer model name.
        end
      end


      # #validate no longer accepts a model since this module instantiates it for you.
      def validate(params, *args)
        super(params, @model, *args)
      end

    private
      def setup!(params)
        @model ||= instantiate_model(params)
      end

      def instantiate_model(params)
        send("#{self.class.action_name}_model", params)
      end

      def create_model(params)
        self.class.model_name.new
      end

      def update_model(params)
        self.class.model_name.find(params[:id])
      end
    end
  end
end