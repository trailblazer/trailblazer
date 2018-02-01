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

      # Currently, adds .class only to classes. this could break builder instances?

      def call(options, name=nil, constant=nil, dsl_block, &block)
        # contract MyForm
        if name.is_a?(Class)
          constant = name
          name     = :default
        end

        is_instance = !(constant.kind_of?(Class) || dsl_block) # i don't like this magic too much, but since it's the only DSL method in TRB, it should be ok. # DISCUSS: options[:is_instance]

        path = path_name(options[:prefix], name, is_instance ? nil : "class") # "contract.default.class"

        if is_instance
          skill = constant
        else
          extended = options[:container][path] # Operation["contract.default.class"]
          extended = yield extended if extended && block_given?

          # only extend an existing skill class when NO constant was passed.
          constant = (extended || options[:class]) if constant.nil?# && block_given?

          skill = Class.new(constant)
          skill.class_eval(&dsl_block) if dsl_block
        end

        [path, skill]
      end

    private
      def path_name(prefix, name, suffix)
        [prefix, name, suffix].compact.join(".") # "contract.class" for default, otherwise "contract.params.class" etc.
      end
    end
  end
end
