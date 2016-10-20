module Trailblazer
  module DSL
    # Boring DSL code that allows to set a skill class, or define it ad-hoc using a block.
    # passing a constant always wipes out the existing class.
    #
    # Used in Contract, Representer, Callback, ..
    class Build
      # options[:prefix]
      # options[:class]
      # options[:container]
      def call(options, name=nil, constant=nil, dsl_block, &block)
        # contract MyForm
        if name.is_a?(Class)
          constant = name
          name     = :default
        end

        path = path_name(options[:prefix], name) # "contract.default.class"

        extended = options[:container][path] # Operation["contract.default.class"]
        extended = yield extended if extended && block_given?

        # only extend an existing skill class when NO constant was passed.
        constant = (extended || options[:class]) if constant.nil?# && block_given?

        skill = Class.new(constant)
        skill.class_eval(&dsl_block) if dsl_block

        [path, skill]
      end

    private
      def path_name(prefix, name)
        [prefix, name, "class"].compact.join(".") # "contract.class" for default, otherwise "contract.params.class" etc.
      end
    end
  end
end
