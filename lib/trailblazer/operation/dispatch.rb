require "declarative"
require "disposable/callback"

module Trailblazer::Operation::Dispatch
  def self.included(base)
    base.extend ClassMethods

    base.extend Declarative::Heritage::Inherited
    base.extend Declarative::Heritage::DSL
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
    def callbacks
      @callbacks ||= {}
    end

    def callback(name=:default, constant=nil, &block)
      return callbacks[name] unless constant or block_given?

      add_callback(name, constant, &block)
    end

  private
    def add_callback(name, constant, &block)
      heritage.record(:add_callback, name, constant, &block)

      callbacks[name] ||= Class.new(constant || Disposable::Callback::Group)
      callbacks[name].class_eval(&block) if block_given?
    end
  end
end