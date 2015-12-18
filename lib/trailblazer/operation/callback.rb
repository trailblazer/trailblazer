require "declarative"
require "disposable/callback"

module Trailblazer::Operation::Callback
  def self.included(base)
    base.extend ClassMethods

    base.extend Declarative::Heritage::Inherited
    base.extend Declarative::Heritage::DSL
  end

  def callback!(name=:default, options={ operation: self, contract: contract, params: @params }) # FIXME: test options.
    config  = self.class.callbacks.fetch(name) # TODO: test exception
    group   = config[:group].new(contract)

    options[:context] ||= (config[:context] == :operation ? self : group)
    group.(options)

    invocations[name] = group
  end

  def dispatch!(*args, &block)
    callback!(*args, &block)
  end

  def invocations
    @invocations ||= {}
  end

  module ClassMethods
    def callbacks
      @callbacks ||= {}
    end

    def callback(name=:default, constant=nil, &block)
      return callbacks[name][:group] unless constant or block_given?

      add_callback(name, constant, &block)
    end

  private
    def add_callback(name, constant, &block)
      heritage.record(:add_callback, name, constant, &block)

      callbacks[name] ||= {
        group:   Class.new(constant || Disposable::Callback::Group),
        context: constant ? nil : :operation # `context: :operation` when the callback is inline. `context: group` otherwise.
      }

      callbacks[name][:group].class_eval(&block) if block_given?
    end
  end
end
