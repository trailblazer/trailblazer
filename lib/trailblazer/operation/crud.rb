module Trailblazer
  class Operation
    # The CRUD module will automatically create/find models for the configured +action+.
    # It adds a public  +Operation#model+ reader to access the model (after performing).
    module CRUD
      attr_reader :model

      module Included
        def included(base)
          base.extend Uber::InheritableAttr
          base.inheritable_attr :config
          base.config = {}

          base.extend ClassMethods
        end
      end
      # this makes ::included overrideable, e.g. to add more featues like CRUD::ActiveModel.
      extend Included


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

        def model_class # considered private.
          self.config[:model] or raise "[Trailblazer] You didn't call Operation::model." # TODO: infer model name.
        end
      end


      # #validate no longer accepts a model since this module instantiates it for you.
      def validate(params, model=self.model, *args)
        super(params, model, *args)
      end

    private
      def model!(params)
        instantiate_model(params)
      end

      def instantiate_model(params)
        send("#{self.class.action_name}_model", params)
      end

      def create_model(params)
        self.class.model_class.new
      end

      def update_model(params)
        self.class.model_class.find(params[:id])
      end

      alias_method :find_model, :update_model

      # Rails-specific.
      # ActiveModel will automatically call Form::model when creating the contract and passes
      # the operation's +::model+, so you don't have to call it twice.
      # This assumes that the form class includes Form::ActiveModel, though.
      module ActiveModel
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def contract(&block)
            super
            contract_class.model(model_class) # this assumes that Form::ActiveModel is mixed in.
          end
        end
      end
    end
  end
end
