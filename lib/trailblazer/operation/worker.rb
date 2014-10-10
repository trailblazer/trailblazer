require 'sidekiq/worker'
# require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'


class Trailblazer::Operation
  # only kicks in when Operation::run, #run will still do it real-time
  module Worker
    def self.included(base)
      base.send(:include, Sidekiq::Worker) # TODO: this will work with any bg gem.
      base.extend(ClassMethods)
    end

    module ClassMethods
      def run(params)
        if background?
          return perform_async(serializable(params))
        end

        new.run(params)
      end

    private
      def background? # TODO: make configurable.
        true
        # if Rails.env == "production" or Rails.env == "staging"
      end

      def serializable(params)
        params # this is where we convert file uloads into Trailblazer::UploadedFile, etc. soon.
      end
    end


    # called from Sidekiq.
    def perform(params)
      # the serialized params hash from Sidekiq contains a Op::UploadedFile hash.

      # the following code is basically what happens in a controller.
      # this is a bug in Rails, it doesn't work without requiring as/hash/ina
      # params = ActiveSupport::HashWithIndifferentAccess.new_from_hash_copying_default(params) # TODO: this might make it ultra-slow as Reform converts it back to strings. fuck that.
      params = params.with_indifferent_access

      run(deserializable(params))
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
          contract_class = new({}).send(:contract_class) # FIXME.

          @file_marshaller_representer ||= contract_class.schema.apply do |dfn|
            dfn.delete!(:prepare)

            dfn.merge!(
              :getter => lambda { |*| self[dfn.name.to_sym] },
              :setter => lambda { |fragment, *| self[dfn.name.to_s] = fragment }
            ) # FIXME: allow both sym and str.

            dfn.merge!(:class => Hash) and next if dfn[:form]
            next unless dfn[:file]

            # TODO: where do we set /tmp/uploads?
            dfn.merge!(
              :serialize   => lambda { |file, *| Trailblazer::Operation::UploadedFile.new(file, :tmp_dir => "/tmp/uploads").to_hash },
              :deserialize => lambda { |object, hash, *| Trailblazer::Operation::UploadedFile.from_hash(hash) },
              :class       => Hash
            )
          end
        end

        def serializable(params)
          file_marshaller_representer.new(params).to_hash
        end
      end

      def deserializable(hash)
          # self.class.file_marshaller_representer.new({}).extend(Representable::Debug).from_hash(hash)
          self.class.file_marshaller_representer.new({}).from_hash(hash)
      end
    end
  end
end