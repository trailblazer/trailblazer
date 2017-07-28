# when __call__ing a nested op, in 2.0 the call would create a new skill with Skill(incoming_options, self.skills)
# we now have to create this manually.  maybe this should be done in __call__ ?


# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)

class Trailblazer::Operation
  def self.Nested(callable, input:nil, output:nil)
    step = Nested.for(callable, input, output)

    [ step, { name: "Nested(#{callable})" } ]
  end

  # WARNING: this is experimental API, but it will end up with something like that.
  module Element
    # DISCUSS: add builders here.
    def initialize(wrapped=nil)
      @wrapped = wrapped
    end

    module Dynamic
      def initialize(wrapped)
        @wrapped = Trailblazer::Option::KW(wrapped)
      end
    end
  end

  module Nested
    # Please note that the instance_variable_get are here on purpose since the
    # superinternal API is not entirely decided, yet.
    # @api private
    def self.for(nested_operation, input, output, is_nestable_object=method(:nestable_object?)) # DISCUSS: use builders here?
      # this calls the actual nested_operation.
      unless is_nestable_object.(nested_operation)
        nested_operation = Caller::Dynamic.new(nested_operation)
      end

      activity_caller    = Trailblazer::Circuit::Nested(nested_operation) do |activity:nil, start_at:nil, args:nil, **|
        activity.__call__(start_at, *args)
      end

      options_for_nested = Options.new
      options_for_nested = Options::Dynamic.new(input) if input # FIXME: they need to have symbol keys!!!!

      options_for_composer = Options::Output.new
      options_for_composer = Options::Output::Dynamic.new(output) if output

      # This lambda is the task added to the circuit, executed at runtime.
      ->(direction, options, flow_options) do
        operation = flow_options[:exec_context]

        options_for_nested = options_for_nested.(operation, options)

        result = activity_caller.(operation, options, options_for_nested, flow_options) # TODO: what about containers?

        options_for_composer.(operation, options, result).each { |k,v| options[k] = v }

        direction = result[0]
        [
        direction.kind_of?(Railway::End::Success) ? # FIXME: redundant logic from Railway::call.
          Trailblazer::Circuit::Right : Trailblazer::Circuit::Left,
        # result.success? # DISCUSS: what if we could simply return the result object here?
         options,
         flow_options
        ]
      end
    end

    def self.nestable_object?(object)
      # interestingly, with < we get a weird nil exception. bug in Ruby?
      object.is_a?(Class) && object <= operation_class
    end

    def self.operation_class
      Trailblazer::Operation
    end

    # Is executed at runtime and calls the nested operation.
# FIXME: this can be removed once this is really just a Circuit::Nested() with a incoming and outgoing options mapper.
    class Caller
      include Element

      def call(input, options, options_for_nested, flow_options)
        call_nested(nested(input, options), options_for_nested, flow_options)
      end

    private
      def call_nested(operation_class, options, flow_options)
        operation_class.__call__(operation_class["__activity__"][:Start], options, flow_options) # FIXME: redundant with Wrap, consolidate!
      end

      def nested(*); @wrapped end

      class Dynamic < Caller
        include Element::Dynamic

        def nested(operation, options)
          @wrapped.(options, exec_context: operation) # FIXME: should we just pass-through flow_options here?
        end
      end
    end

    # Ingoing options when calling a nested task.
    # @note This will be replaced with an ingoing options mapping in the TaskWrap in TRB 2.2.
    class Options
      include Element

      # Per default, only runtime data for nested operation.
      def call(operation, options)
        # this must return a Skill.
        # Trailblazer::Skill::KeywordHash options.to_runtime_data[0]

        # DISCUSS: are we doing the right thing here?

        original, mutable = options.decompose

        original
      end

      # FIXME
      # TODO: rename Context::Hash::Immutable
      class Immutable
        def initialize(hash)
          @hash = hash
        end

        def [](key)
          @hash[key]
        end

        def to_hash # DISCUSS: where do we call this?
          @hash.to_hash # FIXME: should we do this?
        end

        def key?(key)
          @hash.key?(key)
        end

        def merge(hash)
          Immutable.new Trailblazer::Context::ContainerChain.new([hash, @hash]) # DISCUSS: shouldn't a Skill be immutable per default? :D
        end

        # DISCUSS: raise in #[]=
        # each
        # TODO: Skill could inherit
      end

      class Dynamic
        include Element#::Dynamic

        def call(operation, options)
          # Trailblazer::Skill::KeywordHash @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
          original, mutable = options.decompose

          # DISCUSS: how to allow tmp injections?
          # FIXME: almost identical with Option::KW.
          @wrapped.( options, **options.to_hash.merge(
            runtime_data: Immutable.new(original),
            mutable_data: Immutable.new(mutable)
          ) )
        end
      end

      # Outgoing options, the returned options set when calling a nested task.
      # @note This will be replaced with an outgoing options mapping in the TaskWrap in TRB 2.2.
      class Output
        include Element

        def call(input, options, result)
          mutable_data_for(result).each { |k,v| options[k] = v }
        end

        def mutable_data_for(result)
          options = result[1]

          original, mutable = options.decompose

          mutable
        end

        class Dynamic < Output
          include Element#::Dynamic

          def call(input, options, result)
            @wrapped.( options, mutable_data: mutable_data_for(result))
          end
        end
      end
    end
  end
end

