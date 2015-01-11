# FIXME: this will only work for operations embedded in a MODEL namespace.
# this is really hacky and assumes a lot about your structure, but it works for now. don't include it if you don't like it.
Dir.glob("app/concepts/**/crud.rb") do |f|
  path  = f.sub("app/concepts/", "")
  model = path.sub("/crud.rb", "")

  require_dependency "app/models/#{model}" # load the model file, first (thing.rb).
  require_dependency f # load app/concepts/{concept}/crud.rb (Thing::Create, Thing::Update, and so on).
end