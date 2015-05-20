require 'test_helper'
require 'trailblazer/operation/scope'

class ScopeTest < MiniTest::Spec
  class Band < ActiveRecord::Base
    class Index < Trailblazer::Operation
      include CRUD, Scope
      model Thing
      def fetch(params)
        return Band.where(locality: "FR")
      end
    end
  end

  before(:each) do
    Band.create(name: "Band Daft Punk", locality: "FR")
    Band.create(name: "Band Justice", locality: "FR")
    Band.create(name: "Band MSTRKRFT", locality: "CA")
    Band.create(name: "DJ Mr. Oizo", locality: "FR")
    Band.create(name: "DJ Gui Boratto", locality: "BR")
  end
  let (:search) { Band::Index.fetch({q: {name_cont: "Band"}}).search }
  it { search.result.count.must_equal (2) }
end
