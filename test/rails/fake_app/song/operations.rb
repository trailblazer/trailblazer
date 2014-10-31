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
      property :name, validates: {presence: true}
      property :locality
    end

    def process(params)
      validate(params[:band]) do
        contract.save
      end
    end
  end
end