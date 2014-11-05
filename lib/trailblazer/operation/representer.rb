module Trailblazer::Operation::Representer
  def self.included(base)
    base.extend Uber::InheritableAttr
    base.inheritable_attr :representer_class
    # TODO: allow representer without contract?!
    base.extend ClassMethods
  end

  module ClassMethods
    def representer(&block)
      build_representer_class.class_eval(&block)
    end

    def build_representer_class
      representer_class || self.representer_class= Class.new(contract_class.schema)
    end
  end
end