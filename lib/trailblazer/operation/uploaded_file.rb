require 'trailblazer/operation'
require 'action_dispatch/http/upload'
require 'tempfile'

module Trailblazer
  # TODO: document:
  # to_hash
  # from_hash
  # initialize/tmp_dir
  class Operation::UploadedFile
    def initialize(uploaded, options={})
      @uploaded = uploaded
      @options  = options
      @tmp_dir  = options[:tmp_dir]
    end

    def to_hash
      path = persist!

      hash = {
        filename: @uploaded.original_filename,
        type: @uploaded.content_type,
        tempfile_path: path
      }

      cleanup!

      hash
    end

    # Returns a ActionDispatch::Http::UploadedFile as if the upload was in the same request.
    def self.from_hash(hash)
      suffix = File.extname(hash[:filename])

      # we need to create a Tempfile to make Http::UploadedFile work.
      tmp  = Tempfile.new(["bla", suffix]) # always force file suffix to avoid problems with imagemagick etc.
      file = File.open(hash[:tempfile_path])# doesn't close automatically :( # fixme: introduce strategy (Tempfile:=>slow, File:=> hopefully less memory footprint)
      tmp.write(file.read) # DISCUSS: We need Tempfile.new(<File>) to avoid this slow and memory-consuming mechanics.

      file.close # TODO: can we test that?
      File.unlink(file)

      ActionDispatch::Http::UploadedFile.new(hash.merge(tempfile: tmp))
    end

  private
    attr_reader :tmp_dir

     # convert Tempfile from Rails upload into persistent "temp" file so it is available in workers.
    def persist!
      path = @uploaded.path # original Tempfile path (from Rails).
      path = path_with_tmp_dir(path)

      path = path + "_trailblazer_upload"

      FileUtils.mv(@uploaded.path, path) # move Rails upload file into persistent `path`.
      path
    end

    def path_with_tmp_dir(path)
      return path unless tmp_dir # if tmp_dir set, create path in it.

      @with_tmp_dir = Tempfile.new(File.basename(path), tmp_dir)
      @with_tmp_dir.path # use Tempfile to create nested dirs (os-dependent.)
    end

    def delete!(file)
      file.close
      file.unlink # the Rails uploaded file is already unlinked since moved.
    end

    def cleanup!
      delete!(@uploaded.tempfile) if @uploaded.respond_to?(:tempfile) # this is Rails' uploaded file, not sure if we need to do that. in 3.2, we don't have UploadedFile#close, yet.
      delete!(@with_tmp_dir) if @with_tmp_dir # we used that file to create a tmp file path below tmp_dir.
    end
  end
end