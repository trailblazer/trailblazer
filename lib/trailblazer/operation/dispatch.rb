require "disposable/callback"

module Trailblazer::Operation::Dispatch
  def self.included(base)
    base.extend ClassMethods
    base.inheritable_attr :callbacks
    base.callbacks = Representable::Cloneable::Hash.new
  end

  def dispatch!(name=:default)
    group = self.class.callbacks[name].new(contract)
    group.(context: self)

    invocations[name] = group
  end

  def invocations
    @invocations ||= {}
  end

  module ClassMethods
    def callback(name=:default, constant=nil, &block)
      return callbacks[name] unless constant or block_given?


      callbacks[name] ||= constant || Class.new(Disposable::Callback::Group).extend(Representable::Cloneable)
      callbacks[name].class_eval(&block) if block_given?
    end
  end
end