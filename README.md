# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._

In a nutshell: Trailblazer makes you write **logicless models** that purely act as data objects, don't contain callbacks, nested attributes, validations or domain logic. **Controllers** become lean HTTP endpoints. Your **business logic** (including validation) is decoupled from the actual Rails framework and modeled in _operations_.

## Mission

While _Trailblazer_ offers you abstraction layers for all aspects of Ruby On Rails, it does _not_ missionize you. Wherever you want, you may fall back to the "Rails Way" with fat models, monolithic controllers, global helpers, etc. This is not a bad thing, but allows you to step-wise introduce Trailblazer's encapsulation in your app without having to rewrite it.

Trailblazer is all about structure. It helps re-organize existing code into smaller components where different concerns are handled in separated classes. Forms go into form objects, views are object-oriented MVC controllers, the business logic happens in dedicated domain objects backed by completely decoupled persistence objects.

Again, you can pick which layers you want. Trailblazer doesn't impose technical implementations, it offers mature solutions for recurring problems in all types of Rails applications.

Trailblazer is no "complex web of objects and indirection". It solves many problems that have been around for years with a cleanly layered architecture. Only use what you like. And that's the bottom line.


## A Concept-Driven OOP Framework

Trailblazer offers you a new, more intuitive file layout in Rails apps where you structure files by *concepts*.

```
app
├── concepts
│   ├── comment
│   │   ├── cell.rb
│   │   ├── views
│   │   │   ├── show.haml
│   │   │   ├── list.haml
│   │   ├── assets
│   │   │   ├── comment.css.sass
│   │   ├── operation.rb
│   │   ├── twin.rb
```

Files, classes and views that logically belong to one _concept_ are kept in one place. You are free to use additional namespaces within a concept. Trailblazer tries to keep it as simple as possible, though.

## Architecture

Trailblazer extends the conventional MVC stack in Rails. Keep in mind that adding layers doesn't necessarily mean adding more code and complexity.

The opposite is the case: Controller, view and model become lean endpoints for HTTP, rendering and persistence. Redundant code gets eliminated by putting very little application code into the right layer.

![The Trailblazer stack.](https://raw.github.com/apotonick/trailblazer/master/doc/Trb-The-Stack.png)

## Routing

Trailblazer uses Rails routing to map URLs to controllers (we will add simplifications to routing soon).

## Controllers

Controllers are lean endpoints for HTTP. They differentiate between request formats like HTML or JSON and do not contain any business logic. Actions immediately dispatch to an operation.

```ruby
class CommentsController < ApplicationController
  def create
    Comment::Create.(params)
  end
```

This can be simplified using the `run` method and allows you a simple conditional to handle failing operations.

```ruby
class CommentsController < ApplicationController
  def create
    run Comment::Create do |op|
      return redirect_to(comment_path op.model) # success.
    end

    render :new # re-render form.
  end
```

Again, the controller only knows how to dispatch to the operation and what to do for success and invalid processing. While business affairs (e.g. logging or rollbacks) are to be handled in the operation, the controller invokes rendering or redirecting.

## Operation

The [API is documented here](http://trailblazerb.org/gems/operation/api.html).

Operations encapsulate business logic and are the heart of a Trailblazer architecture. One operation per high-level domain _function_ is used. Different formats or environments are handled in subclasses. Operations don't know about HTTP or the environment.

An operation is not just a monolithic replacement for your business code. An operation is a simple orchestrator between the form object, models and your business code.

You don't have to use the form/contract if you don't want it, BTW.

```ruby
class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    def process(params)
      # do whatever you feel like.
    end
  end
end
```

Operations only need to implement `#process` which receives the params from the caller.

## Validations

Operations usually have a form object which is simply a `Reform::Form` class. All the [API documented in Reform](https://github.com/apotonick/reform) can be applied and used.

The operation makes use of the form object using the `#validate` method.

```ruby
class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    contract do
      property :body, validates: {presence: true}
    end

    def process(params)
      @model = Comment.new

      validate(params[:comment], @model) do |f|
        f.save
      end
    end
  end
end
```

The contract (aka _form_) is defined in the `::contract` block. You can implement nested forms, default values, validations, and everything else Reform provides.

In case of a valid form the block for `#validate` is invoked. It receives the populated form object. You can use the form to save data or write your own logic. This is where your business logic is implemented, and in turn could be an invocation of service objects or organizers.

Technically speaking, what really happens in `Operation#validate` is the following.

```ruby
contract_class.new(@model).validate(params[:comment])
```

This is a familiar work-flow from Reform. Validation does _not_ touch the model.




If you prefer keeping your forms in separate classes or even files, you're free to do so.

```ruby
class Create < Trailblazer::Operation
  self.contract_class = MyCommentForm
```

## Callbacks

Post-processing logic (also known as _callbacks_) is configured in operations.

Following the schema of your contract, you can define callbacks for events tracked by the form's twin.

```ruby
class Create < Trailblazer::Operation
  callback(:after_save) do
    on_change :upload_file, property: :file

    property :user do
      on_create :notify_user!
    end
  end
```

The _Imperative Callback_ pattern then allows you to call this _callback group_ whereever you need it.

```ruby
class Create < Trailblazer::Operation

  def process(params)
    validate(params) do
      contract.save
      dispatch!(:after_save)
    end
  end
end
```

No magical triggering of unwanted logic anymore, but explicit invocations where you want it.


## Models

Models for persistence can be implemented using any ORM you fancy, for instance [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord#active-record--object-relational-mapping-in-rails) or [Datamapper](http://datamapper.org/).

In Trailblazer, models are completely empty. They solely contain associations and finders. No business logic is allowed in models.

```ruby
class Thing < ActiveRecord::Base
  has_many :comments, -> { order(created_at: :desc) }
  has_many :users, through: :authorships
  has_many :authorships

  scope :latest, lambda { all.limit(9).order("id DESC") }
end
```

Only operations and views/cells can access models directly.


## Views

View rendering can happen using the controller as known from Rails. This is absolutely fine for simple views.

More complex UI logic happens in _View Models_ as found in [Cells](https://github.com/apotonick/cells). View models also replace helpers.


## Representers

Operations can use representers from [Roar](https://github.com/apotonick/roar) to serialize and parse JSON and XML documents for APIs.

Representers can be inferred automatically from your contract, then may be refined, e.g. with hypermedia or a format like `JSON-API`.

```ruby
class Create < Trailblazer::Operation

  representer do
    # inherited :body
    include Roar::JSON::HAL

    link(:self) { comment_path(represented.id) }
  end
```

The operation can then parse incoming JSON documents in `validate` and render a document via `to_json`. The full [documentation is here](http://trailblazerb.org/gems/operation/representer.html) or in the [Trailblazer book](https://leanpub.com/trailblazer), chapter _Hypermedia APIs_.

## Tests

Subject to tests are mainly _Operation_s and _View Model_s, as they encapsulate endpoint behaviour of your app. As a nice side effect, factories are replaced by simple _Operation_ calls.



## Overview

Trailblazer is basically a mash-up of mature gems that have been developed over the past 10 years and are used in hundreds and thousands of production apps.

Using the different layers is completely optional and up to you: Both Cells and Reform can be excluded from your stack if you wish so.

## Controller API

[Learn more](http://trailblazerb.org/gems/operation/controller.html)

Trailblazer provides four methods to present and invoke operations. But before that, you need to include the `Controller` module.

```ruby
class CommentsController < ApplicationController
  include Trailblazer::Operation::Controller
```

### Rendering the form object

Operations can populate and present their form object so it can be used with `simple_form` and other form helpers.

```ruby

def new
  form Comment::Create
end
```

This will run the operation but _not_ its `validate` code. It then sets the `@form` instance variable in the controller so it can be rendered.

```haml
= form_for @form do |f|
  = f.input f.body
```

`#form` is meant for HTML actions like `#new` and `#edit`, only.

### Running an operation

If you do not intend to maintain different request formats, the easiest is to use `#run` to process incoming data using an operation.

```ruby
def create
  run Comment::Create
end
```

This will simply run `Comment::Create[params]`.

You can pass your own params, too.

```ruby
def create
  run Comment::Create, params.merge({current_user: current_user})
end
```

An additional block will be executed _only if_ the operation result is valid.

```ruby
def create
  run Comment::Create do |op|
    return redirect_to(comments_path, notice: op.message)
  end
end
```

Note that the operation instance is yielded to the block.

The case of an invalid response can be handled after the block.

```ruby
def create
  run Comment::Create do |op|
    # valid code..
    return
  end

  render action: :new
end
```

Don't forget to `return` from the valid block, otherwise both the valid block _and_ the invalid calls after it will be invoked.

### Responding

Alternatively, you can use Rails' excellent `#respond_with` to let a responder take care of what to render. Operations can be passed into `respond_with`. This happens automatically in `#respond`, the third way to let Trailblazer invoke an operation.

```ruby
def create
  respond Comment::Create
end
```

This will simply run the operation and chuck the instance into the responder letting the latter sort out what to render or where to redirect. The operation delegates respective calls to its internal `model`.

`#respond` will accept options to be passed on to `respond_with`, too

```ruby
respond Comment::Create, params, location: brandnew_comments_path
```

You can also handle different formats in that block. It is totally fine to do that in the controller as this is _endpoint_ logic that is HTTP-specific and not business.

```ruby
def create
  respond Comment::Create do |op, formats|
    formats.html { redirect_to(op.model, :notice => op.valid? ? "All good!" : "Fail!") }
    formats.json { render nothing: true }
  end
end
```

The block passed to `#respond` is _always_ executed, regardless of the operation's validity result. Goal is to let the responder handle the validity of the operation.

The `formats` object is simply passed on to `#respond_with`.

### Presenting

For `#show` actions that simply present the model using a HTML page or a JSON or XML document the `#present` method comes in handy.

```ruby
def show
  present Comment::Update
end
```

Again, this will only run the operation's setup and provide the model in `@model`. You can then use a cell or controller view for HTML to present the model.

For document-based APIs and request types that are not HTTP the operation will be advised to render the JSON or XML document using the operation's representer.

Note that `#present` will leave rendering up to you - `respond_to` is _not_ called.


In all three cases the following instance variables are assigned: `@operation`, `@form`, `@model`.

Named instance variables can be included, too. This is documented [here](#named-controller-instance-variables).


### Different Request Formats

In case you have document-API operations that use representers to deserialize the incoming JSON or XML: You can configure the controller to pass the original request body into the operation via `params["comment"]` - instead of the pre-parsed hash from Rails.

You need to configure this in the controller.

```ruby
class CommentsController < ApplicationController
  operation document_formats: :json
```


It's up to the operation's builder to decide which class to instantiate.

```ruby
class Create < Trailblazer::Operation
  builds do |params|
    JSON if params[:format] == "json"
  end
end
```

[Note that this will soon be provided with a module.]


## Operation API

### Call style

The simplest way of running an operation is the _call style_.

```ruby
op = Comment::Create.(params)
```

The call style runs the operation and return the operation instance, only.

In case of an invalid operation, this will raise an exception.

### Run style

The _run style_ will do the same as call, but won't raise an exception in case of an invalid result. Instead, it returns result _and_ the operation instance.

```ruby
result, op = Comment::Create.run(params)
```

Additionally, it accepts a block that's only run for a valid state.

```ruby
Comment::Create.run(params) do |op|
  # only run when valid.
end
```

## Form API

Usually, an operation has a form object.

```ruby
class Create < Trailblazer::Operation
  contract do
    property :body
    validates :body: presence: true, length: {max: 160}
  end
```

A `::contract` block simply opens a new Reform class for you.

```ruby
contract do #=> Class.new(Reform::Form) do
```

This allows using Reform's API in the block.

When inheriting, the block is `class_eval`ed in the inherited class' context and allows adding, removing and customizing the sub contract.

### CRUD Semantics

You can make Trailblazer find and create models for you using the `CRUD` module.

```ruby
require 'trailblazer/operation/crud'

class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include CRUD
    model Comment, :create

    contract do
      # ..
    end

    def process(params)
      validate(params[:comment]) do |f|
        f.save
      end
    end
  end
end
```

You have to tell `CRUD` the model class and what action to implement using `::model`.

Note how you do not have to pass the `@model` to validate anymore. Also, the `@model` gets created automatically and is accessable using `Operation#model`.

In inherited operations, you can override the action, only, using `::action`.

```ruby
class Update < Create
  action :update
end
```

Another action is `:find` (which is currently doing the same as `:update`) to find a model by using `params[:id]`.


### Normalizing params

Override `#setup_params!` to add or remove values to params before the operation is run.

```ruby
class Create < Trailblazer::Operation
  def process(params)
    params #=> {show_all: true, admin: true, .. }
  end

  private
    def setup_params!(params)
      params.merge!(show_all: true) if params[:admin]
    end
  end
end
```

This centralizes params normalization and doesn't require you to do that manually in `#process`.

### Collections

Operations can also be used to present (and soon to process) collections of objects, e.g. for an `Index` operation. This is [documented here](http://trailblazerb.org/gems/operation/collection.html).

### Background Processing

To run an operation in Sidekiq (ActiveJob-support coming!) all you need to do is include the `Worker` module.

```ruby
require 'trailblazer/operation/worker'

class Comment::Image::Crop < Trailblazer::Operation
  include Worker

  def process(params)
    # will be run asynchronously.
  end
end
```


### Worker::FileMarshaller: needs representable 2.1.1 (.schema)


### Testing Operations

## Autoloading

Use our autoloading if you dislike explicit requires.

You can just add

```ruby
require "trailblazer/autoloading"
```

to `config/initializers/trailblazer.rb` and implementation classes like `Operation` will be automatically loaded.

## Operation Autoloading

If you structure your CRUD operations using the `app/concepts/*/crud.rb` file layout we use in the book, the `crud.rb` files are not gonna be found by Rails automatically. It is a good idea to enable CRUD autoloading.

At the end of your `config/application.rb` file, add the following.

```ruby
require "trailblazer/rails/railtie"
```

This will go through `app/concepts/`, find all the `crud.rb` files, autoload their corresponding namespace (e.g. `Thing`, which is a model) and then load the `crud.rb` file.


## Undocumented Features

(Please don't read this section!)



### Named Controller Instance Variables

If you want to include named instance variables for you views you must include another ActiveRecord specific module.

```ruby
require 'trailblazer/operation/controller/active_record'

class ApplicationController < ActionController::Base
  include Trailblazer::Operation::Controller
  include Trailblazer::Operation::Controller::ActiveRecord
end
```

This will setup a named instance variable of your operation's model, for example `@song`.

## The Book

![](https://raw.githubusercontent.com/apotonick/trailblazer/master/doc/trb.jpg)

Please buy my book [Trailblazer - A new architecture for Rails](https://leanpub.com/trailblazer) and [let me know](http://twitter.com/apotonick) what you think! I am still working on the book but keep adding new chapters every other week. It will be about 300 pages and we're developing a real, full-blown Rails/Trb application.

The [demo application](https://github.com/apotonick/gemgem-trbrb) implements what we discuss in the book.

## Why?

* Grouping code, views and assets by concepts increases the **maintainability** of your apps. Developers will find their way faster into your structure as the file layout is more intuitive.
* Finding bugs gets less frustrating as encapsulated layers allow **testing components** in total isolation. Once you know your form and your view are ok, it must be the parsing code.
* The reusability of code increases drastically as Trailblazer gently pushes you towards encapsulation. No more redundant helpers but clean inheritance.
* No more surprises from ActiveRecord's massive API. The separation between persistence and domain automatically results in smaller, less destructive APIs for your models.
