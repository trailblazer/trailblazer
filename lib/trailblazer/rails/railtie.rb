require "rails/railtie"
module Trailblazer
  class Railtie < ::Rails::Railtie
    def self.autoload_operations(app)
      Dir.glob("app/concepts/**/crud.rb") do |f|
        path  = f.sub("app/concepts/", "")
        model = path.sub("/crud.rb", "")

        require_dependency "#{app.root}/app/models/#{model}" # load the model file, first (thing.rb).
        require_dependency "#{app.root}/#{f}" # load app/concepts/{concept}/crud.rb (Thing::Create, Thing::Update, and so on).
      end
    end

    def self.autoload_cells(app)
      Dir.glob("app/concepts/**/*cell.rb") do |f|
        require_dependency "#{app.root}/#{f}" # load app/concepts/{concept}/cell.rb.
      end
    end

    # This is to autoload Operation::Dispatch, etc. I'm simply assuming people find this helpful in Rails.
    initializer "trailblazer.library_autoloading" do
      require "trailblazer/autoloading"
    end

    # thank you, http://stackoverflow.com/a/17573888/465070
    initializer 'trailblazer.install', after: :load_config_initializers do |app|
      # the trb autoloading has to be run after initializers have been loaded, so we can tweak inclusion of features in
      # initializers.
      ActionDispatch::Reloader.to_prepare do
        Trailblazer::Railtie.autoload_operations(app)
        Trailblazer::Railtie.autoload_cells(app)
      end
    end
  end
end
