require 'test_helper'
require 'trailblazer/operation'
require 'trailblazer/operation/modelless'

class ModellessTest < MiniTest::Spec
  class CreateOperation < Trailblazer::Operation
    include Modelless

    contract do
      property :email
      validates :email, presence: true
    end

    def process(params)
      validate(params[:contact]) do |f|
        f.save do |data|
          params[:process].(data)
        end
      end
    end
  end


  # processes the data for you.
  it do
    CreateOperation.(contact: {email: "visitor@example.com"},
                     process: ->(data) { data.must_equal "email" => "visitor@example.com" })
  end

  # doesn't process invalid data
  it do
    assert_raises(Trailblazer::Operation::InvalidContract) { CreateOperation.(contact: {}) }
  end
end
