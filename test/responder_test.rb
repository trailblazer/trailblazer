require 'test_helper'
require 'trailblazer/operation/responder'

class Song
  extend ActiveModel::Naming

  class Operation < Trailblazer::Operation
    include Model
    model Song
    include Responder

    def process(params)
      invalid! if params == false
    end
  end
end

module MyApp
  class Song
    extend ActiveModel::Naming

    class Operation < Trailblazer::Operation
      include Model
      include Responder
      model Song

      def process(params)
        invalid! if params == false
      end
    end
  end
end

class ResponderTestForModelWithoutNamespace < MiniTest::Spec

  # test ::model_name
  it { Song::Operation.model_name.name.must_equal "Song" }
  it { Song::Operation.model_name.singular.must_equal "song" }
  it { Song::Operation.model_name.plural.must_equal "songs" }
  it { Song::Operation.model_name.element.must_equal "song" }
  it { Song::Operation.model_name.human.must_equal "Song" }
  it { Song::Operation.model_name.collection.must_equal "songs" }
  it { Song::Operation.model_name.param_key.must_equal "song" }
  it { Song::Operation.model_name.i18n_key.must_equal :"song" }
  it { Song::Operation.model_name.route_key.must_equal "songs" }
  it { Song::Operation.model_name.singular_route_key.must_equal "song" }

  # #errors
  it { Song::Operation.(true).errors.must_equal [] }
  it { Song::Operation.(false).errors.must_equal [1] } # TODO: since we don't want responder to render anything, just return _one_ error. :)

  # TODO: integration test with Controller.
end


class ResponderTestForModelWitNamespace < MiniTest::Spec

    # test ::model_name
    it { MyApp::Song::Operation.model_name.name.must_equal "MyApp::Song" }
    it { MyApp::Song::Operation.model_name.singular.must_equal "my_app_song" }
    it { MyApp::Song::Operation.model_name.plural.must_equal "my_app_songs" }
    it { MyApp::Song::Operation.model_name.element.must_equal "song" }
    it { MyApp::Song::Operation.model_name.human.must_equal "Song" }
    it { MyApp::Song::Operation.model_name.collection.must_equal "my_app/songs" }
    it { MyApp::Song::Operation.model_name.param_key.must_equal "my_app_song" } # "song" for AR.
    it { MyApp::Song::Operation.model_name.i18n_key.must_equal :"my_app/song" }
    it { MyApp::Song::Operation.model_name.route_key.must_equal "my_app_songs" } # "songs" for AR.
    it { MyApp::Song::Operation.model_name.singular_route_key.must_equal "my_app_song" } # "song" for AR.

    # #errors
    it { MyApp::Song::Operation.(true).errors.must_equal [] }
    it { MyApp::Song::Operation.(false).errors.must_equal [1] } # TODO: since we don't want responder to render anything, just return _one_ error. :)

    # TODO: integration test with Controller.
end