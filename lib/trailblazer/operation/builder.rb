require "uber/builder"

# Allows to add builders via ::builds.
module Trailblazer::Operation::Builder
  def self.extended(extender)
    extender.send(:include, Uber::Builder)
  end

  def builder_class
    @builders
  end

  def builder_class=(constant)
    @builders = constant
  end

private
  # Runs the builders for this operation class to figure out the actual class.
  def build_operation_class(*params)
    class_builder(self).call(*params) # Uber::Builder::class_builder(context)
  end

  def build_operation(params, options={})
    build_operation_class(*params).new(options)
  end
end