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
        end

        def action(name)
          self.config[:action] = name
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
        send("#{self.class.config[:action]}_model", params)
      end

      def create_model(params)
        self.class.config[:model].new
      end
    end
  end
end