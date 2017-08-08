# when __call__ing a nested op, in 2.0 the call would create a new skill with Skill(incoming_options, self.skills)
# we now have to create this manually.  maybe this should be done in __call__ ?


# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)

class Trailblazer::Operation
  def self.Nested(callable, input:nil, output:nil)
    task = Nested.for(callable, input, output)

    if Nested.nestable_object?( callable  ) # FIXME: COMPAT, defaults for dynamics.
      raise callable["__activity__"].to_fields[1].inspect

      connections = callable["__activity__"].events.end.collect { |name, event| [event, [:End, name]] } # [ [End::PassFast, [:End, :pass_fast]],   [End::Left, [:End, :left]] ]
    else
      connections = []
    end

    [ task, { name: "Nested(#{callable})" }, {}, { connections: connections } ]
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
      # TODO: this will be done via incoming/outgoing contracts.
      options_for_nested = Options.new
      options_for_nested = Options::Dynamic.new(input) if input # FIXME: they need to have symbol keys!!!!

      options_for_composer = Options::Output.new
      options_for_composer = Options::Output::Dynamic.new(output) if output




      # this calls the actual nested_operation.
      unless is_nestable_object.(nested_operation)
        nested_operation = DynamicNested.new(nested_operation)
      end


      # The returned {Nested} instance is a valid circuit element and will be `call`ed in the circuit.
      # It simply returns the nested activity's direction.
      # The actual wiring - where to go with that, is up to the Nested() macro.
      Trailblazer::Circuit::Nested(nested_operation, nil) do |activity:nil, start_at:nil, args:nil, **|
        options, flow_options = args

        operation = flow_options[:exec_context]

        options_for_nested = options_for_nested.(operation, options) # discuss: why do we need the operation here at all?


        direction, options, flow_options = activity.__call__(start_at, *args)

        # options_for_composer.(operation, options, result).each { |k,v| options[k] = v }

        [ direction, options, flow_options ]
      end
    end

    def self.nestable_object?(object)
      # interestingly, with < we get a weird nil exception. bug in Ruby?
      object.is_a?(Class) && object <= operation_class
    end

    def self.operation_class
      Trailblazer::Operation
    end

    private

    class DynamicNested
      include Element

      def __call__(direction, options, flow_options)
        @wrapped.(options, flow_options).__call__(direction, options, flow_options)
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

