module Trailblazer::Operation::Stepable
  Configuration = Struct.new(:module, :args, :block)

  def [](*args, &block)
    Configuration.new(self, args, block)
  end
end
