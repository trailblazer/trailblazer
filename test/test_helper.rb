require 'trailblazer'
require 'minitest/autorun'

module TmpUploads
  extend ActiveSupport::Concern

  included do
    let (:tmp_dir) { "/tmp/uploads" }
    before { Dir.mkdir(tmp_dir) unless File.exists?(tmp_dir) }
  end
end

MiniTest::Spec.class_eval do
  include TmpUploads
end