module Trailblazer
  class NotAuthorizedError < RuntimeError
  end

  module Operation::Policy
    def self.included(base)
      # base.extend Uber::InheritableAttr
      # base.inheritable_attr :_representer_class
      base.extend ClassMethods
    end

    module ClassMethods
      def policy(*args, &block)
        @policies = [block]
      end

      attr_reader :policies
    end

    def setup!(params)
      super
      instance_exec params, &self.class.policies.first or raise NotAuthorizedError
      #
      # NotAuthorizedError.new(query: query, record: record, policy: policy)
    end
  end
end