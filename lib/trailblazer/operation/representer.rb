module Trailblazer::Operation::Representer
  # TODO: test me.

  def self.included(base)
    base.extend Uber::InheritableAttr
    base.inheritable_attr :representer_class
    # TODO: allow representer without contract?!
    # TODO: we have to extract the schema here, not subclass the contract.
    base.representer_class = Class.new(base.contract_class.representer_class)
    base.extend ClassMethods
  end

  module ClassMethods
    def representer(&block)
      representer_class.class_eval(&block)
    end
  end
end