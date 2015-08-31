class Trailblazer::Operation
  module CRUD
    # Builds (finds or creates) the model _before_ the operation is instantiated.
    # This allows to use the model in builders.
    #
    # Note: THIS IS EXPERIMENTAL!!!
    module ClassBuilder # CRUD::ForClass :OnClass ModelFromClass ClassModel ExternalModel
      def self.included(includer)
        includer.extend CRUD::DSL
        includer.extend CRUD::ModelBuilder
        includer.extend ClassMethods
      end


      def initialize(model, options)
        super(options) # TODO: run #setup! here.
        @model = model
      end

      def model!(*) # FIXME: move #setup! etc into #initialize.
        @model
      end


      module ClassMethods
      private
        def build_operation(params, options={})
          puts "@@@@@=====> #{params.inspect}"
          model = model!(*params)
          build_operation_class(model, *params).new(model, options)
          # super([model, params], [model, options]) # calls: builds ->(model, params), and Op.new(model, params)
        end
      end
    end
  end
end