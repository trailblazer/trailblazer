require 'test_helper'
require 'trailblazer/operation/scope'

class ScopeTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class Index < Trailblazer::Operation
      include CRUD, Scope
      model Thing
    end
  end

  before(:each) do
    Thing.create(title: "Band Nofx")
    Thing.create(title: "Singer Jim")
    Thing.create(title: "My Band Ramones")
  end
  let (:search) { Thing::Index.fetch({q: {title_cont: "Band"}}).search }
  it { search.result.count.must_equal (2) }
end
