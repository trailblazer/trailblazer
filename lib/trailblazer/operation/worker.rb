require 'sidekiq/worker'
require 'active_support/core_ext/hash/indifferent_access'


class Trailblazer::Operation
  # only kicks in when Operation::run, #run will still do it real-time
  # Works with Reform 2, only.
  module Worker
    def self.included(base)
      base.send(:include, Sidekiq::Worker)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def run(params)
        if background?
          return perform_async(serializable(params))
        end

        super(params)
      end

      def new(*args)
        return super if args.any?
        # sidekiq behavior: (not a big fan of this)
        self
      end

      def perform(params) # called by Sidekiq.
        build_operation(params).perform
      end

      def jid=(jid)
        puts "@@@@@ #{jid.inspect}"
      end

    private
      def perform_async(*args)
        client_push('class' => self, 'args' => args) # calls class.new.perform(params)
      end

      def background? # TODO: make configurable.
        true
        # if Rails.env == "production" or Rails.env == "staging"
      end

      def serializable(params)
        params # this is where we convert file uloads into Trailblazer::UploadedFile, etc. soon.
      end
    end


    def perform#(params)
      # the serialized params hash from Sidekiq contains a Op::UploadedFile hash.

      # the following code is basically what happens in a controller.
      # this is a bug in Rails, it doesn't work without requiring as/hash/ina
      # params = ActiveSupport::HashWithIndifferentAccess.new_from_hash_copying_default(params) # TODO: this might make it ultra-slow as Reform converts it back to strings.
      params = @params.with_indifferent_access
      @params = deserializable(params)
      run
    end

  private
    def deserializable(params)
      params # this is where we convert file uloads into Trailblazer::UploadedFile, etc. soon.
    end


    # Overrides ::serializable and #deserializable and handles file properties from the Contract schema.
    module FileMarshaller
      # NOTE: this is WIP and the implementation will be more understandable and performant soon.
      def self.included(base)
        base.extend ClassMethods
      end


    private
      module ClassMethods
        def file_marshaller_representer
          @file_marshaller_representer ||= contract_class.schema(include: [Representable::Hash]).apply do |dfn|
            dfn.merge!(
              getter: lambda { |*| self[dfn.name.to_sym] },
              setter: lambda { |fragment, *| self[dfn.name.to_s] = fragment }
            ) # FIXME: allow both sym and str.

            dfn.merge!(class: Hash) and next if dfn[:form] or dfn[:twin] # nested properties need a class for deserialization.
            next unless dfn[:file]

            # TODO: where do we set /tmp/uploads?
            dfn.merge!(
              serialize: lambda { |file, *| Trailblazer::Operation::UploadedFile.new(file, tmp_dir: "/tmp/uploads").to_hash },
              deserialize: lambda { |object, hash, *| Trailblazer::Operation::UploadedFile.from_hash(hash) },
              class: Hash
            )
          end
        end

        def serializable(params)
          file_marshaller_representer.new(params).to_hash
        end
      end

      # todo: do with_indifferent_access in #deserialize and call super here.
      def deserializable(hash)
        # self.class.file_marshaller_representer.new({}).extend(Representable::Debug).from_hash(hash)
        self.class.file_marshaller_representer.new({}.with_indifferent_access).from_hash(hash)
      end
    end
  end
end