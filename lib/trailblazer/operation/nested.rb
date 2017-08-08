# when __call__ing a nested op, in 2.0 the call would create a new skill with Skill(incoming_options, self.skills)
# we now have to create this manually.  maybe this should be done in __call__ ?


# per default, everything we pass into a circuit is immutable. it's the ops/act's job to allow writing (via a Context)

class Trailblazer::Operation
  def self.Nested(callable, input:nil, output:nil, name: "Nested(#{callable})")
    task = Nested.for(callable, input, output)

    activity_outputs = if Nested.nestable_object?( callable  ) # FIXME: COMPAT, defaults for dynamics.
      # TODO: introduce Activity interface (for introspection, events, etc)
      end_events = callable["__activity__"].to_fields[1]

      Hash[
        end_events.collect do |evt|
          _name = evt.instance_variable_get(:@name)
          [ evt, { role: _name } ] # this is a wild guess, e.g. PassFast => { role: :pass_fast }
        end
      ]
    else
      {}
    end

    [ task, { name: name }, {}, activity_outputs ]
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


      nested_activity = is_nestable_object.(nested_operation) ? nested_operation : DynamicNested.new(nested_operation)

      # The returned {Nested} instance is a valid circuit element and will be `call`ed in the circuit.
      # It simply returns the nested activity's direction.
      # The actual wiring - where to go with that, is up to the Nested() macro.
      puts "@@@@@ #{nested_activity.inspect}"
      Trailblazer::Circuit::Nested(nested_activity, nil) do |activity:nil, start_at:, args:raise, **|
        options, flow_options = args

        operation = flow_options[:exec_context]

        _options_for_nested = options_for_nested.(operation, options) # discuss: why do we need the operation here at all?

        puts "N@@@@@ #{activity} #{_options_for_nested}"
        direction, options, flow_options = activity.__call__( activity.instance_variable_get(:@start), _options_for_nested, flow_options )

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
      include Element::Dynamic

      def __call__(direction, options, flow_options)
        # puts "~~~@@@@@ #{options.inspect}"
        operation = @wrapped.(options, flow_options)

        direction ||= operation.instance_variable_get(:@start)
        operation.__call__(direction, options, flow_options)
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

        Trailblazer::Context::Immutable.new(Trailblazer::Context(original))
      end

      class Dynamic
        include Element#::Dynamic

        def call(operation, options)
          # Trailblazer::Skill::KeywordHash @wrapped.(operation, options, runtime_data: options.to_runtime_data[0], mutable_data: options.to_mutable_data )
          original, mutable = options.decompose

          # DISCUSS: how to allow tmp injections?
          # FIXME: almost identical with Option::KW.
          @wrapped.( options, **options.to_hash.merge(
            runtime_data: Context::Immutable.new(original),
            mutable_data: Context::Immutable.new(mutable)
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

