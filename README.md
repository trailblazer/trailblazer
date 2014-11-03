# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._

In a nutshell: Trailblazer makes you write **logicless models** that purely act as data objects, don't contain callbacks, nested attributes, validations or domain logic. It **removes bulky controllers** and strong_parameters by supplying additional layers to hold that code and **completely replaces helpers**.

Please sign up for my upcoming book [Trailblazer - A new architecture for Rails](https://leanpub.com/trailblazer) and check out the free sample chapter!

The free [sample application] implements what we discuss in the book.

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

Traiblazer uses Rails routing to map URLs to controllers (we will add simplifications to routing soon).

## Controllers

Controllers are lean endpoints for HTTP. They differentiate between request formats like HTML or JSON and immediately dispatch to an operation. Controllers do not contain any business logic.

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

Note that the operation instance is yield to the block.

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
  present Comment::Create
end
```

Again, this will only run the operation's setup and provide the model in `@model`. You can then use a cell or controller view for HTML to present the model.

For document-based APIs and request types that are not HTTP the operation will be advised to render the JSON or XML document using the operation's representer.

Note that `#present` will also work instead of `#form` (allowing it to be used in `#new` and `#edit`, too) as the responder will _not_ trigger any rendering in those actions.

### Controller API

In all three cases the following instance variables are assigned: `@operation`, `@form`, `@model`.

## Operation

Operations encapsulate business logic. One operation per high-level domain _function_ is used. Different formats or environments are handled in subclasses. Operations don't know about HTTP.

```ruby
class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    def process(params)
      # do whatever you feel like.
      self
    end
  end
end
 ```

Operations only need to implement `#process` which receives the params from the caller.

### Call style

The simplest way of running an operation is the _call style_.

```ruby
op = Comment::Create[params]
```

Using `Operation#[]` will return the operation instance. In case of an invalid operation, this will raise an exception.

Note how this can easily be used for test factories.

```ruby
let(:comment) { Comment::Create[valid_comment_params].model }
```

Using operations as test factories is a fundamental concept of Trailblazer to remove buggy redundancy in tests and manual factories.

### Run style

You can run an operation manually and use the same block semantics as found in the controller.

```ruby
Comment::Create.run(params) do |op|
  # only run when valid.
end
```

Of course, this does _not_ throw an exception but simply skips the block when the operation is invalid.

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

In case of a valid form the block for `#validate` is invoked. It receives the populated form object. You can use the form to save data or write your own logic.

Technically speaking, what really happens in `Operation#validate` is the following.

```ruby
contract_class.new(@model).validate(params[:comment])
```

This is a familiar work-flow from Reform. Validation does _not_ touch the model.


## Models

Models for persistence can be implemented using any ORM you fancy, for instance [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord#active-record--object-relational-mapping-in-rails) or [Datamapper](http://datamapper.org/).

In Trailblazer, models are completely empty and solely configure database-relevant directives and associations. No business logic is allowed in models. Only operations, views and cells can access models directly.

## Views

View rendering can happen using the controller as known from Rails. This is absolutely fine for simple views.

More complex UI logic happens in _View Models_ as found in [Cells](https://github.com/apotonick/cells). View models also replace helpers.




8. **HTTP API** Consuming and rendering API documents (e.g. JSON or XML) is done via [roar](https://github.com/apotonick/roar) and [representable](https://github.com/apotonick/representable). They usually inherit the schema from <em>Contract</em>s .

10. **Tests** Subject to tests are mainly <em>Operation</em>s and <em>View Model</em>s, as they encapsulate endpoint behaviour of your app. As a nice side effect, factories are replaced by simple _Operation_ calls.

Trailblazer is basically a mash-up of mature gems that have been developed over the past 10 years and are used in hundreds and thousands of production apps.


## Controller API

### Normalizing params

Override `#process_params!` to add or remove values to `params` before the operation is run. This is called in `#run`, `#respond` and `#present`.

```ruby
class CommentsController < ApplicationController
  # ..

private
  def process_params!(params)
    params.merge!(current_user: current_user)
  end
end
```

This centralizes params normalization and doesn't require you to do that in every action manually.


### Different Request Formats

The controller helpers `#present` and `#respond` automatically pass the request body into the operation via the `params` hash. It's up to the operation's builder to decide which class to instantiate.

```ruby
class Create < Trailblazer::Operation
  builds do |params|
    JSON if params[:format] == "json"
  end
end
```

[Note that this will soon be provided with a module.]


## Operation API

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

### Background Processing

To run an operation in Sidekiq (ActiveJob-support coming!) all you need to do is include the `Worker` module.

```ruby
require 'trailblazer/operation/worker'

class Comment::Image::Crop < Trailblazer::Operation
  include Worker

  def process(params)
    # will be run asynchronous.
  end
end
```

### Rendering Operation's Form

You have access to an operation's form using `::contract`.

```ruby
Comment::Create.contract(params)
```

This will run the operation's `#process` method _without_ the validate block and return the contract.

### Marking Operation as Invalid

Sometimes you don't need a form object but still want the validity behavior of an operation.

```ruby
def process(params)
  return invalid!(self) unless params[:id]

  Comment.find(params[:id]).destroy
  self
end
```


### Worker::FileMarshaller: needs representable 2.1.1 (.schema)


### Testing Operations

## Autoloading

Use our autoloading if you dislike explicit requires.

You can just add

```ruby
require 'trailblazer/autoloading'
```

to `config/initializers/trailblazer.rb` and files will be "automatically" loaded.



## Why?

* Grouping code, views and assets by concepts increases the **maintainability** of your apps. Developers will find their way faster into your structure as the file layout is more intuitive.
* Finding bugs gets less frustrating as encapsulated layers allow **testing components** in total isolation. Once you know your form and your view are ok, it must be the parsing code.
* The reusability of code increases drastically as Trailblazer gently pushes you towards encapsulation. No more redundant helpers but clean inheritance.
* No more surprises from ActiveRecord's massive API. The separation between persistence and domain automatically results in smaller, less destructive APIs for your models.
