# Trailblazer

_Trailblazer provides new high-level abstractions for Ruby frameworks. It gently enforces encapsulation, an intuitive code structure and approaches the modeling of complex business workflows with a functional mind-set._

[![Zulip chat](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://trailblazer.zulipchat.com)
[![TRB Newsletter](https://img.shields.io/badge/TRB-newsletter-lightgrey.svg)](http://trailblazer.to/newsletter/)
[![Gem Version](https://badge.fury.io/rb/trailblazer.svg)](http://badge.fury.io/rb/trailblazer)
[![Open Source Helpers](https://www.codetriage.com/trailblazer/trailblazer/badges/users.svg)](https://www.codetriage.com/trailblazer/trailblazer)

## Documentation

* **The current version is Trailblazer 2.1.** We do have [comprehensive API documenation](https://trailblazer.to/2.1/docs/trailblazer.html) ready for you. If you're new to TRB start with our [LEARN page](https://trailblazer.to/2.1/learn.html).
* A migration guide from 2.0 can be found [on our website](https://trailblazer.to/2.1/docs/trailblazer.html#trailblazer-2-1-migration).
* The [1.x documentation is here](http://trailblazer.to/gems/operation/1.1/).

Make sure to check out the new beginner's guide to learning Trailblazer. The [brand-new book](https://leanpub.com/buildalib) discusses all aspects in a step-wise approach you need to understand Trailblazer's mechanics and design ideas.

<a href="https://leanpub.com/buildalib"><img src="https://trailblazer.to/images/2.1/buildalib-cover.png"></a>

## Screencasts

Watch our series of screencasts **TRAILBLAZER TALES** if you prefer learning from videos!

<iframe width="560" height="315" src="https://www.youtube.com/embed/9elpobV4HSw" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Trailblazer In A Nutshell

1. All business logic is encapsulated in [operations](#operation) (service objects).
3. [Controllers](#controllers) instantly delegate to an operation. No business code in controllers, only HTTP-specific logic.
4. [Models](#models) are persistence-only and solely define associations and scopes. No business code is to be found here. No validations, no callbacks.
5. The presentation layer offers optional [view models](#views) (Cells) and [representers](#representers) for document APIs.
6. More complex business flows and life-cycles are modeled using workflows.

Want code? Jump [right here](#controllers)!

## Mission

While _Trailblazer_ offers you abstraction layers for all aspects of Ruby On Rails, it does _not_ missionize you. Wherever you want, you may fall back to the "Rails Way" with fat models, monolithic controllers, global helpers, etc. This is not a bad thing, but allows you to step-wise introduce Trailblazer's encapsulation in your app without having to rewrite it.

Trailblazer is all about structure. It helps re-organize existing code into smaller components where different concerns are handled in separated classes.

Again, you can pick which layers you want. Trailblazer doesn't impose technical implementations, it offers mature solutions for recurring problems in all types of Rails applications.

Trailblazer is no "complex web of objects and indirection". It solves many problems that have been around for years with a cleanly layered architecture. Only use what you like. And that's the bottom line.

## Concepts over Technology

Trailblazer offers you a new, more intuitive file layout in applications.

```
app
├── concepts
│   ├── song
│   │   ├── operation
│   │   │   ├── create.rb
│   │   │   ├── update.rb
│   │   ├── contract
│   │   │   ├── create.rb
│   │   │   ├── update.rb
│   │   ├── cell
│   │   │   ├── show.rb
│   │   │   ├── index.rb
│   │   ├── view
│   │   │   ├── show.haml
│   │   │   ├── index.rb
│   │   │   ├── song.css.sass
```

Instead of grouping by technology, classes and views are structured by *concept*, and then by technology. A concept can relate to a model, or can be a completely abstract concern such as `invoicing`.

Within a concept, you can have any level of nesting. For example, `invoicing/pdf/` could be one.


## Architecture

Trailblazer extends the conventional MVC stack in Rails. Keep in mind that adding layers doesn't necessarily mean adding more code and complexity.

The opposite is the case: Controller, view and model become lean endpoints for HTTP, rendering and persistence. Redundant code gets eliminated by putting very little application code into the right layer.

![The Trailblazer stack.](https://raw.github.com/apotonick/trailblazer/master/doc/operation-2017.png)

## Routing

Trailblazer uses Rails routing to map URLs to controllers, because it works.

```ruby
Rails.application.routes.draw do
  resources :songs
end
```

## Controllers

Controllers are lean endpoints for HTTP. They do not contain any business logic. Actions immediately dispatch to an operation.

```ruby
class SongsController < ApplicationController
  def create
    run Song::Create # Song::Create is an operation class.
  end
end
```

The `#run` method invokes the operation. It allows you to run a conditional block of logic if the operation was successful.

```ruby
class SongsController < ApplicationController
  def create
    run Song::Create do |op|
      return redirect_to(song_path op.model) # success!
    end

    render :new # invalid. re-render form.
  end
end
```

Again, the controller only dispatchs to the operation and handles successful/invalid processing on the HTTP level. For instance by redirecting, setting flash messages, or signing in a user.

[Learn more.](http://trailblazer.to/gems/operation/controller.html)

## Operation

Operations encapsulate business logic and are the heart of a Trailblazer architecture.

The bare bones operation without any Trailblazery is implemented in [the `trailblazer-operation` gem](https://github.com/trailblazer/trailblazer-operation) and can be used without our stack.

Operations don't know about HTTP or the environment. You could use an operation in Rails, Hanami, or Roda, it wouldn't know.

An operation is not just a monolithic replacement for your business code. It's a simple orchestrator between the form objects, models, your business code and all other layers needed to get the job done.

```ruby
class Song::Create < Trailblazer::Operation
  step :model
  step :validate

  def model(ctx, **)
    # do whatever you feel like.
    ctx[:model] = Song.new
  end

  def validate(ctx, params:, **)
    # ..
  end
end
```

Operations define the flow of their logic using the DSL and implement the particular steps with pure Ruby.

You cannot instantiate them per design. The only way to invoke them is `call`.

```ruby
Song::Create.(params: {whatever: "goes", in: "here"})
```

Their high degree of encapsulation makes them a [replacement for test factories](#tests), too.

[Learn more.](https://2019.trailblazer.to/2.1/docs/operation.html#operation-overview)

## Models

Models for persistence can be implemented using any ORM you fancy, for instance [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord#active-record--object-relational-mapping-in-rails) or [Datamapper](http://datamapper.org/).

In Trailblazer, models are completely empty. They solely contain associations and finders. No business logic is allowed in models.

```ruby
class Song < ActiveRecord::Base
  belongs_to :thing

  scope :latest, lambda { all.limit(9).order("id DESC") }
end
```

Only operations and views/cells can access models directly.

## Tests

In Trailblazer, you only have operation unit tests and integration smoke tests to test the operation/controller wiring.

Operations completely replace the need for leaky factories.

```ruby
describe Song::Update do
  let(:song) { Song::Create.(song: {body: "[That](http://trailblazer.to)!"}) }
end
```

## Workflow
Operations are a great way to clean up controllers and models. However, Trailblazer goes further and provides an approach to model entire life-cycles of business objects, such as "a song" or "the root user" using workflow ([`pro feature`](https://2019.trailblazer.to/2.1/docs/pro.html#pro-1)). Also, you don't have to use the DSL but can use the [`editor`](https://2019.trailblazer.to/2.1/docs/pro.html#pro-editor) instead (cool for more complex, long-running flows). Here comes a sample screenshot.

<img src="http://2019.trailblazer.to/2.1/dist/img/flow.png">

## Installation

The obvious needs to be in your `Gemfile`.

```ruby
gem "trailblazer"
gem "trailblazer-rails" # if you are in rails.
gem "trailblazer-cells"
```

Cells is _not_ required per default! Add it if you use it, which is highly recommended.
