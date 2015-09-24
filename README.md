# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._

[![Gem Version](https://badge.fury.io/rb/trailblazer.svg)](http://badge.fury.io/rb/trailblazer)
[![Gitter Chat](https://badges.gitter.im/trailblazer/chat.svg)](https://gitter.im/trailblazer/chat)


## Trailblazer In A Nutshell

1. All business logic is encapsulated in [operations](#operation) (service objects).
  * An optional Reform [form](#validations) object in the operation deserializes and validates input. The form object can also be used for rendering.
  * An optional [policy](#policies) object blocks unauthorized users from running the operation.
  * Optional [callback](#callbacks) objects allow declaring post-processing logic.
3. [Controllers](#controllers) instantly delegate to an operation. No business code in controllers, only HTTP-specific logic.
4. [Models](#models) are persistence-only and solely define associations and scopes. No business code is to be found here. No validations, no callbacks.
5. The presentation layer offers optional [view models](#cells) (Cells) and [representers](#representers) for document APIs.

Trailblazer is designed to handle different contexts like user roles by applying [inheritance](#inheritance) between and [composing](#composing) of operations, form objects, policies, representers and callbacks.



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

You don't have to use the form/contract if you don't want it.

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

The _Imperative Callback_ pattern then allows you to call this _callback group_ wherever you need it.

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

## Policies

The full documentation for [Policy is here](http://trailblazerb.org/gems/operation/policy.html).

You can abort running an operation using a policy. "[Pundit](https://github.com/elabs/pundit)-style" policy classes define the rules.

```ruby
class Thing::Policy
  def initialize(user, thing)
    @user, @thing = user, thing
  end

  def create?
    @user.admin?
  end
end
```

The rule is enabled via the `::policy` call.

```ruby
class Thing::Create < Trailblazer::Operation
  include Policy

  policy Thing::Policy, :create?
```

The policy is evaluated in `#setup!`, raises an exception if `false` and suppresses running `#process`.

```ruby
Thing::Create.(current_user: User.find(1), thing: {}) # raises exception.
```

You can query the `policy` object at any point in your operation without raising an exception.

To [use policies in your builders](http://trailblazerb.org/gems/operation/builder#resolver.html), please read the documentation.

```ruby
class Thing::Create < Trailblazer::Operation
  include Resolver

  builder-> (model, policy, params) do
    return Admin if policy.admin?
    return SignedIn if params[:current_user]
  end
```

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

Subject to tests are mainly _Operation_s and _View Model_s, as they encapsulate endpoint behavior of your app. As a nice side effect, factories are replaced by simple _Operation_ calls.



## Overview

Trailblazer is a collection of mature gems that have been developed over the past 10 years and are used in thousands of production apps.

Using the different layers is completely optional and up to you: Both Cells and Reform can be excluded from your stack if you wish so.

## Controller API

[Learn more](http://trailblazerb.org/gems/operation/controller.html)

Trailblazer provides four methods to present and invoke operations. But before that, you need to include the `Controller` module.

```ruby
class CommentsController < ApplicationController
  include Trailblazer::Operation::Controller
```

### Running an operation

If you do not intend to maintain different request formats, the easiest is to use `#run` to process incoming data using an operation.

```ruby
def create
  run Comment::Create
end
```

This will simply run `Comment::Create[params]`.





----

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

### Inheritance

Operations fully support inheritance and will copy the contract, the callback groups and any methods from the original operation class.

```ruby
class Create < Trailblazer::Operation
  contract do
    property :title
  end

  callback(:before_save) do
    on_change :notify!
  end

  def notify!(*)
  end
end
```

This happens with normal Ruby inheritance.

```ruby
class Update < Create
  # inherited:
  # contract
  # callback(:before_save)
  # def notify!(*)
end
```

You can customize callback groups and contracts using the `:inherit` option, add and remove properties or add methods.

[Learn more](http://trailblazerb.org/gems/operation/inheritance.html)

### Modules

In case inheritance is not enough for you, use modules to share common functionality.

```ruby
module ExtendedCreate
  include Trailblazer::Operation::Module

  contract do
    property :id
  end

  callback do
    on_update :update!
  end

  def update!(song)
    # do something
  end
end
```

Modules can be included and will simply run the declarations in the including class.

```ruby
class Create::Admin < Create
  include ExtendedCreate

  # contract has :title and :id now.
```

Modules are often used to modify an existing operation for admin or signed-in roles.

[Learn more](http://trailblazerb.org/gems/operation/inheritance.html)


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

You can make Trailblazer find and create models for you using the `Model` module.

```ruby
require 'trailblazer/operation/model'

class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include Model
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

You have to tell `Model` the model class and what action to implement using `::model`.

Note how you do not have to pass the `@model` to validate anymore. Also, the `@model` gets created automatically and is accessible using `Operation#model`.

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


## Installation

The obvious needs to be in your `Gemfile`.

```ruby
gem "trailblazer"
gem "trailblazer-rails" # if you are in rails.
gem "cells"
```

Cells is _not_ required per default! Add it if you use it, which is highly recommended.

A few quirks are required at the moment as Rails autoloading is giving us a hard time. The setup of an app [is documented here](https://github.com/apotonick/gemgem-trbrb/wiki/Things-You-Should-Know).

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
