require "disposable/callback"

class Trailblazer::Operation
  def self.Callback(group)
    step = ->(input, options) { Callback.(group, input, options) }

    [ step, name: "callback.#{group}" ]
  end

  module Callback
    def self.call(name=:default, operation, options)
      config  = options["callback.#{name}.class"] || raise #.fetch(name) # TODO: test exception
      group   = config[:group].new(options["contract.default"])

      options[:context] ||= (config[:context] == :operation ? operation : group)
      group.(options)

      options["result.callback.#{name}"] = group
    end

    module DSL
      def callback(name=:default, constant=nil, &block)
        heritage.record(:callback, name, constant, &block)

        # FIXME: make this nicer. we want to extend same-named callback groups.
        # TODO: allow the same with contract, or better, test it!
        extended = self["callback.#{name}.class"] && self["callback.#{name}.class"]

        path, group_class = Trailblazer::DSL::Build.new.({ prefix: :callback, class: Disposable::Callback::Group, container: self }, name, constant, block) { |extended| extended[:group] }

        self[path] = { group: group_class, context: constant ? nil : :operation }
      end
    end
  end
end
