require 'uber/builder'
# TODO: extract all reform-contract stuff into optional module.
require 'reform'

# TODO: OP[] without wrapper, OP.run with (eg for params)

# to be documented: only implement #setup! when not using CRUD and when ::present needed (make example for simple Op without #setup!)

module Trailblazer
  class Operation
    extend Uber::InheritableAttr
    inheritable_attr :contract_class
    self.contract_class = Reform::Form.clone
    self.contract_class.class_eval do
      def self.name # FIXME: don't use ActiveModel::Validations in Reform, it sucks.
        # for whatever reason, validations climb up the inheritance tree and require _every_ class to have a name (4.1).
        "Reform::Form"
      end
    end

    class << self
      def run(*params, &block) # Endpoint behaviour
        res, op = build_operation_class(*params).new.run(*params)

        if block_given?
          yield op if res
          return op
        end

        [res, op]
      end

      # ::call only returns the Operation instance (or whatever was returned from #validate).
      # This is useful in tests or in irb, e.g. when using Op as a factory and you already know it's valid.
      def call(*params)
        build_operation_class(*params).new(raise_on_invalid: true).run(*params).last
      end
      alias_method :[], :call # TODO: deprecate #[] in favor of .().

      # Runs #process without validate and returns the form object.
      def present(*params)
        build_operation_class(*params).new.present(*params)
      end

      def contract(&block)
        contract_class.class_eval(&block)
      end
      
      def collection(*params, &block)
        *params = {} if params.empty?
        res, op = build_operation_class(*params).new.fetch_collection(*params)

        if block_given?
          yield op if res
          return op
        end

        op
      end
      alias_method :fetch, :collection

    private
      def build_operation_class(*params)
        class_builder.call(*params) # Uber::Builder::class_builder
      end
    end

    include Uber::Builder
    attr_reader :collection, :search

    def initialize(options={})
      @valid            = true
      @raise_on_invalid = options[:raise_on_invalid] || false
    end

    #   Operation.run(body: "Fabulous!") #=> [true, <Comment body: "Fabulous!">]
    def run(*params)
      setup!(*params) # where do we assign/find the model?

      process(*params)

      [valid?, self]
    end
    
    def fetch_collection(*params)
      setup_collection!(*params)
      
      @collection = fetch(*params)
      @search = perform_search(*params) if self.respond_to?(:perform_search)
      @collection = perform_pagination(*params) if self.respond_to?(:perform_pagination)

      [self, valid?].reverse
    end

    def present(*params)
      setup!(*params)

      @contract = contract_for(nil, @model)
      self
    end

    attr_reader :contract

    def errors
      contract.errors
    end

    def valid?
      @valid
    end
    
    def to_model
      @model
    end

  private
    def setup_collection!(*params)
      setup_params!(*params)
    end
  
    def setup!(*params)
      setup_params!(*params)

      @model = model!(*params)
      setup_model!(*params)
    end

    # Implement #model! to find/create your operation model (if required).
    def model!(*params)
    end

    # Override to add attributes that can be infered from params.
    def setup_model!(*params)
    end

    def setup_params!(*params)
    end

    def validate(params, model, contract_class=nil)
      @contract = contract_for(contract_class, model)

      if @valid = contract.validate(params)
        yield contract if block_given?
      else
        raise!(contract)
      end

      @valid
    end

    def invalid!(result=self)
      @valid = false
      result
    end

    # When using Op::[], an invalid contract will raise an exception.
    def raise!(contract)
      raise InvalidContract.new(contract.errors.to_s) if @raise_on_invalid
    end

    # Instantiate the contract, either by using the user's contract passed into #validate
    # or infer the Operation contract.
    def contract_for(contract_class, *model)
      (contract_class || self.class.contract_class).new(*model)
    end

    class InvalidContract < RuntimeError
    end
  end
end

require 'trailblazer/operation/crud'
require "trailblazer/operation/dispatch"

# run
#   setup
#   process
#     contract
#     validate
