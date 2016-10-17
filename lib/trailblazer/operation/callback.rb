require "declarative"
require "disposable/callback"

module Trailblazer::Operation::Callback
  def self.included(includer)
    includer.extend DSL

    includer.extend Declarative::Heritage::Inherited
    includer.extend Declarative::Heritage::DSL
  end

  def callback!(name=:default, options={ operation: self, contract: contract, params: @params }) # FIXME: test options.
    config  = self["callback.#{name}.class"] || raise #.fetch(name) # TODO: test exception
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

  module DSL
    def callback(name=:default, constant=nil, &block)
      heritage.record(:callback, name, constant, &block)

      # FIXME: make this nicer. we want to extend same-named callback groups.
      # TODO: allow the same with contract, or better, test it!
      extended = self["callback.#{name}.class"] && self["callback.#{name}.class"][:group]

      path, group_class = Trailblazer::Competences::Build.new.({ prefix: :callback, class: extended||Disposable::Callback::Group }, name, constant, &block)

      self[path] = { group: group_class, context: constant ? nil : :operation }
    end
  end
end
