# FIXME: this will only work for operations embedded in a MODEL namespace.
# this is really hacky and assumes a lot about your structure, but it works for now. don't include it if you don't like it.
Dir.glob("app/concepts/**/crud.rb") do |f|
  path = f.sub("app/concepts/", "")

  path.sub("/crud.rb", "").camelize.constantize # load the model first (Thing).
  require_dependency path # load model/crud.rb (Thing::Create, Thing::Update, and so on).
end