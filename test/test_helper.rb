require 'trailblazer'
require 'minitest/autorun'

module TmpUploads
  extend ActiveSupport::Concern
  fs_dir = File.join(File.dirname(__FILE__), '..', 'tmp', 'uploads')
  FileUtils.mkdir_p(fs_dir) unless File.exist?(fs_dir)

  included do
    let(:tmp_dir) { File.expand_path(fs_dir) }
  end
end

MiniTest::Spec.class_eval do
  include TmpUploads
end