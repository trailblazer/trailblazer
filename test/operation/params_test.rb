require "test_helper"
require "trailblazer/operation/params"

class OperationParamsTest < MiniTest::Spec
  #---
  # in call(params) and process(params), argument is always self["params"]
  class Find < Trailblazer::Operation
    def process(params); self["eql?"] = self["params"].object_id==params.object_id end
  end
  class Seek < Trailblazer::Operation
    include Test::ReturnCall
    def call(params); self["eql?"] = self["params"].object_id==params.object_id end
  end


  it { Find.({ id: 1 })["eql?"].must_equal true }
  # self["params"] is what gets passed in.
  it { Find.({ id: 1 })["params"].must_equal({ id: 1 }) }
  it { Seek.({ id: 1 }).must_equal true }


  #---
  # change self["params"] via Operation#
  class Create < Trailblazer::Operation
    include Params
    def process(params) self[:x] = params end
    def params!(params); params.merge(garrett: "Rocks!") end
  end

  # allows you changing params in #setup_params!.
  it {
    result = Create.( id: 1 )
    result["params"].inspect.must_equal %{{:id=>1, :garrett=>\"Rocks!\"}}
    result["params.original"].inspect.must_equal %{{:id=>1}}
  }
end
