require "test_helper"

class DocsMacroTest < Minitest::Spec
  #:simple
  module Macro
    def self.MyPolicy(allowed_role: "admin")
      step = ->(input, options) { options["current_user"].type == allowed_role }

      [ step, name: "my_policy.#{allowed_role}" ] # :before, :replace, etc. work, too.
    end
  end
  #:simple end

  #:simple-op
  class Create < Trailblazer::Operation
    step Macro::MyPolicy( allowed_role: "manager" )
    # ..
  end
  #:simple-op end

=begin
  it do
  #:simple-pipe
    puts Create["pipetree"].inspect(style: :rows) #=>
     0 ========================>operation.new
     1 ====================>my_policy.manager
  #:simple-pipe end
  end
=end

  it { Operation::Inspect.(Create).must_equal %{[>my_policy.manager]} }
end

# injectable option
# nested pipe
# using macros in macros
