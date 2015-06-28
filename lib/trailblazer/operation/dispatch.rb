require "disposable/callback"

module Trailblazer::Operation::Dispatch
  def dispatch!(name=:default)
    group = self.class.callbacks[name].new(contract)
    group.(context: self)

    invocations[name] = group
  end

  def invocations
    @invocations ||= {}
  end


  module ClassMethods
    def callback(name=:default, *args, &block)
      callbacks[name] ||= Class.new(Disposable::Callback::Group).extend(Representable::Cloneable)
      callbacks[name].class_eval(&block)
    end
  end

  def self.included(base)
    base.extend ClassMethods
    base.extend Uber::InheritableAttr
    base.inheritable_attr :callbacks
    base.callbacks = Representable::Cloneable::Hash.new
  end
end