# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._

[![Gitter Chat](https://badges.gitter.im/trailblazer/chat.svg)](https://gitter.im/trailblazer/chat)
[![TRB Newsletter](https://img.shields.io/badge/TRB-newsletter-lightgrey.svg)](http://trailblazer.to/newsletter/)
[![Gem Version](https://badge.fury.io/rb/trailblazer.svg)](http://badge.fury.io/rb/trailblazer)


## Trailblazer In A Nutshell

1. All business logic is encapsulated in [operations](#operation) (service objects).
  * An optional Reform [form](#validations) object in the operation deserializes and validates input. The form object can also be used for rendering.
  * An optional [policy](#policies) object blocks unauthorized users from running the operation.
  * Optional [callback](#callbacks) objects allow declaring post-processing logic.
3. [Controllers](#controllers) instantly delegate to an operation. No business code in controllers, only HTTP-specific logic.
4. [Models](#models) are persistence-only and solely define associations and scopes. No business code is to be found here. No validations, no callbacks.
5. The presentation layer offers optional [view models](#views) (Cells) and [representers](#representers) for document APIs.

Trailblazer is designed to handle different contexts like user roles by applying [inheritance](#inheritance) between and [composing](#composing) of operations, form objects, policies, representers and callbacks.

Wanna see some code? Jump [right here](#controllers)!

## Mission

While _Trailblazer_ offers you abstraction layers for all aspects of Ruby On Rails, it does _not_ missionize you. Wherever you want, you may fall back to the "Rails Way" with fat models, monolithic controllers, global helpers, etc. This is not a bad thing, but allows you to step-wise introduce Trailblazer's encapsulation in your app without having to rewrite it.

Trailblazer is all about structure. It helps re-organize existing code into smaller components where different concerns are handled in separated classes.

Again, you can pick which layers you want. Trailblazer doesn't impose technical implementations, it offers mature solutions for recurring problems in all types of Rails applications.

Trailblazer is no "complex web of objects and indirection". It solves many problems that have been around for years with a cleanly layered architecture. Only use what you like. And that's the bottom line.

## Trailblazer Likes 'Em All

Since Trailblazer decouples the High-Level Stack from the framework, it runs with virtually any Ruby framework. We are constantly working on documenting how to do that.

* Trailblazer with Rails [Book](http://trailblazer.to/books/trailblazer.html) | [Repository](https://github.com/apotonick/gemgem-trbrb)
* Trailblazer with Sinatra [Guide](http://trailblazer.to/guides/sinatra/getting-started.html) | [Repository](https://github.com/apotonick/gemgem-sinatra)
* Trailblazer with Hanami - coming soon!
* Trailblazer with Roda - coming soon!
* Trailblazer with Grape - coming _very_ soon!


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

Trailblazer uses Rails routing to map URLs to controllers, because it works.

```ruby
Rails.application.routes.draw do
  resources :comments
end
```

## Controllers

Controllers are lean endpoints for HTTP. They do not contain any business logic. Actions immediately dispatch to an operation.

```ruby
class CommentsController < ApplicationController
  def create
    run Comment::Create # Comment::Create is an operation class.
  end
```

The `#run` method invokes the operation. It allows you to run a conditional block of logic if the operation was successful.

```ruby
class CommentsController < ApplicationController
  def create
    run Comment::Create do |op|
      return redirect_to(comment_path op.model) # success!
    end

    render :new # invalid. re-render form.
  end
```

Again, the controller only dispatchs to the operation and handles successful/invalid processing on the HTTP level. For instance by redirecting, setting flash messages, or signing in a user.

[Learn more.](http://trailblazer.to/gems/operation/controller.html)

## Operation

Operations encapsulate business logic and are the heart of a Trailblazer architecture.

Operations don't know about HTTP or the environment. You could use an operation in Rails, Hanami, or Roda, it wouldn't know. This makes them an ideal replacement for test factories.

An operation is not just a monolithic replacement for your business code. It's a simple orchestrator between the form object, models and your business code.

```ruby
class Comment::Create < Trailblazer::Operation
  def process(params)
    # do whatever you feel like.
  end
end
```

Operations only need to implement `#process` which receives the params from the caller.

[Learn more.](http://trailblazer.to/gems/operation)

## Validations

In Trailblazer, an operation (usually) has a form object which is simply a `Reform::Form` class. All the [API documented in Reform](https://github.com/apotonick/reform) can be applied and used.

The operation makes use of the form object using the `#validate` method.

```ruby
class Comment::Create < Trailblazer::Operation
  contract do
    # this is a Reform::Form class!
    property :body, validates: {presence: true}
  end

  def process(params)
    @model = Comment.new

    validate(params[:comment], @model) do |f|
      f.save
    end
  end
end
```

The contract (aka _form_) is defined in the `::contract` block. You can implement nested forms, default values, validations, and everything else Reform provides.

In the `#process` method you can define your business logic.

[Learn more.](http://trailblazer.to/gems/operation/api.html)

## Callbacks

Post-processing logic (also known as _callbacks_) is configured in operations.

Callbacks can be defined in groups. They use the form object's state tracking to find out whether they should be run.

```ruby
class Comment::Create < Trailblazer::Operation
  include Callback
  callback(:after_save) do
    on_change :markdownize_body! # this is only run when the form object has changed.
  end
```

Callbacks are never triggered automatically, you have to invoke them! This is called _Imperative Callback_.

```ruby
class Comment::Create < Trailblazer::Operation
  include Callback
  def process(params)
    validate(params) do
      contract.save
      callback!(:after_save) # run markdownize_body!, but only if form changed.
    end
  end

  def markdownize_body!(comment)
    comment.body = Markdownize.(comment.body)
  end
end
```

No magical triggering of unwanted logic anymore, but explicit invocations where you want it.

[Learn more.](http://trailblazer.to/gems/operation/callback.html)

## Models

Models for persistence can be implemented using any ORM you fancy, for instance [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord#active-record--object-relational-mapping-in-rails) or [Datamapper](http://datamapper.org/).

In Trailblazer, models are completely empty. They solely contain associations and finders. No business logic is allowed in models.

```ruby
class Comment < ActiveRecord::Base
  belongs_to :thing

  scope :latest, lambda { all.limit(9).order("id DESC") }
end
```

Only operations and views/cells can access models directly.

## Policies

You can abort running an operation using a policy. "[Pundit](https://github.com/elabs/pundit)-style" policy classes define the rules.

```ruby
class Comment::Policy
  def initialize(user, comment)
    @user, @comment = user, comment
  end

  def create?
    @user.admin?
  end
end
```

The rule is enabled via the `::policy` call.

```ruby
class Comment::Create < Trailblazer::Operation
  include Policy

  policy Comment::Policy, :create?
```

The policy is evaluated in `#setup!`, raises an exception if `false` and suppresses running `#process`.

[Learn more.](http://trailblazer.to/gems/operation/policy.html)

## Views

View rendering can happen using the controller as known from Rails. This is absolutely fine for simple views.

More complex UI logic happens in _View Models_ as found in [Cells](https://github.com/apotonick/cells). View models also replace helpers.

The operation's form object can be rendered in views, too.

```ruby
class CommentsController < ApplicationController
  def new
    form Comment::Create # will assign the form object to @form.
  end
```

Since Reform objects can be passed to form builders, you can use the operation to render and process the form!

```haml
= simple_form_for @form do |f|
  = f.input :body
```


## Representers

Operations can use representers from [Roar](https://github.com/apotonick/roar) to serialize and parse JSON and XML documents for APIs.

Representers can be inferred automatically from your contract, then may be refined, e.g. with hypermedia or a format like `JSON-API`.

```ruby
class Comment::Create < Trailblazer::Operation
  representer do
    # inherited :body
    include Roar::JSON::HAL

    link(:self) { comment_path(represented.id) }
  end
```

The operation can then parse incoming JSON documents in `validate` and render a document via `to_json`.

[Learn more.](http://trailblazer.to/gems/operation/representer.html)

## Tests

In Trailblazer, you only have operation unit tests and integration smoke tests to test the operation/controller wiring.

Operations completely replace the need for leaky factories.

```ruby
describe Comment::Update do
  let(:comment) { Comment::Create.(comment: {body: "[That](http://trailblazer.to)!"}) }
```

## More

Trailblazer has many more architectural features such as

* Polymorphic builders and operations
* Inheritance and composition support
* Polymorphic views

Check the project website and the book.

## Installation

The obvious needs to be in your `Gemfile`.

```ruby
gem "trailblazer"
gem "trailblazer-rails" # if you are in rails.
gem "cells"
```

Cells is _not_ required per default! Add it if you use it, which is highly recommended.

## The Book

![](https://raw.githubusercontent.com/apotonick/trailblazer/master/doc/trb.jpg)

Please buy it: [Trailblazer - A new architecture for Rails](https://leanpub.com/trailblazer).

The [demo application](https://github.com/apotonick/gemgem-trbrb) implements what we discuss in the book.

