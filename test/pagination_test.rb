require 'test_helper'
require 'trailblazer/operation/pagination'

class PaginationSetupTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class Index < Trailblazer::Operation
      include CRUD, Pagination
      model Thing
    end
  end

  before(:each) do
    Thing.create(title: "Thing 1")
    Thing.create(title: "Thing 2")
  end
  let (:collection) { Thing::Index.fetch.collection }
  it { collection.respond_to?(:page).must_equal (true) }
  it { collection.count.must_equal (2) }
end

class PaginationTotalPagesTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class Index < Trailblazer::Operation
      include CRUD, Pagination
      model Thing
    end
  end

  before(:each) do
    Thing.create(title: "Thing 1")
    Thing.create(title: "Thing 2")
    Thing.create(title: "Thing 3")
    Thing.create(title: "Thing 4")
    Thing.create(title: "Thing 5")
  end
  let (:collection_first_page) { Thing::Index.fetch({per_page: 2, page: 1}).collection }
  it { collection_first_page.total_pages.must_equal (3) }
  it { collection_first_page.count.must_equal (2) }
  let (:collection_last_page) { Thing::Index.fetch({per_page: 2, page: 3}).collection }
  it { collection_last_page.total_pages.must_equal (3) }
  it { collection_last_page.count .must_equal (1) }
end
