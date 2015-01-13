module Trailblazer
  class Railtie < Rails::Railtie
    def self.autoload_crud_operations
      Dir.glob("app/concepts/**/crud.rb") do |f|
        path  = f.sub("app/concepts/", "")
        model = path.sub("/crud.rb", "")

        require_dependency "app/models/#{model}" # load the model file, first (thing.rb).
        require_dependency f # load app/concepts/{concept}/crud.rb (Thing::Create, Thing::Update, and so on).
      end
    end




    # thank you, http://stackoverflow.com/a/17573888/465070
    initializer 'trailblazer.install' do
      if Rails.configuration.cache_classes
        #FooBar.install!
      else
        ActionDispatch::Reloader.to_prepare do
          Trailblazer::Railtie.autoload_crud_operations
        end
      end
    end
  end
end
