module Trailblazer
  class Railtie < Rails::Railtie
    def self.autoload_crud_operations(app)
      Dir.glob("app/concepts/**/crud.rb") do |f|
        path  = f.sub("app/concepts/", "")
        model = path.sub("/crud.rb", "")

        require_dependency "#{app.root}/app/models/#{model}" # load the model file, first (thing.rb).
        require_dependency "#{app.root}/#{f}" # load app/concepts/{concept}/crud.rb (Thing::Create, Thing::Update, and so on).
      end
    end

    # thank you, http://stackoverflow.com/a/17573888/465070
    initializer 'trailblazer.install', after: :load_config_initializers do |app|
      # the trb autoloading has to be run after initializers have been loaded, so we can tweak inclusion of features in
      # initializers.
      ActionDispatch::Reloader.to_prepare do
        Trailblazer::Railtie.autoload_crud_operations(app)
      end
    end
  end
end
