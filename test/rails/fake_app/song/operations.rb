class Song < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD
    include Responder
    model Song, :create


    contract do
      property :title, validates: {presence: true}
      property :length
    end

    def process(params)
      validate(params[:song]) do
        contract.save
      end
    end
  end


  class Delete < Create
    action :find

    def process(params)
      model.destroy
      self
    end
  end
end

class Band < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD, Responder
    model Band, :create

    contract do
      include Reform::Form::ActiveModel
      model Band

      property :name, validates: {presence: true}
      property :locality
    end

    def process(params)
      validate(params[:band]) do
        contract.save
      end
    end

    class JSON < self
      include Representer
      # self.representer_class = Class.new(contract_class)
      # representer_class do
      #   include Reform::Form::JSON
      # end
    end

    builds do |params|
      JSON if params[:format] == "json"
    end
  end

  class Update < Create
    action :update

    # TODO: infer stuff per default.
    class JSON < self
      include Representer
    end

    builds do |params|
      JSON if params[:format] == "json"
    end
  end
end