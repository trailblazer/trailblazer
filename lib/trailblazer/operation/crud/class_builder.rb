class Trailblazer::Operation
  module CRUD
    # Builds (finds or creates) the model _before_ the operation is instantiated.
    # Passes the model instance into the builder with the following signature.
    #
    #   builds ->(model, params)
    #
    # Note: THIS IS EXPERIMENTAL!!!
    module ClassBuilder # CRUD::ForClass :OnClass ModelFromClass ClassModel ExternalModel
      def self.included(includer)
        includer.extend CRUD::DSL
        includer.extend CRUD::BuildModel
        includer.extend ClassMethods
      end


      def initialize(model, options)
        super(options) # TODO: run #setup! here.
        @model = model
      end # in #run, @model is overridden, again. this is only because we want sidekiq-style (op.new()) actually i don't like this.

      def model!(*) # FIXME: move #setup! etc into #initialize.
        # then we don't have to override this and can simply assign @model after super in initialize.
        @model
      end


      module ClassMethods
      private
        def build_operation(params, options={})
          model = model!(*params)
          build_operation_class(model, *params).new(model, options)
          # super([model, params], [model, options]) # calls: builds ->(model, params), and Op.new(model, params)
        end
      end
    end
  end
end