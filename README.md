# Trailblazer

_Trailblazer provides new high-level abstractions for Ruby frameworks. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._

[![Gitter Chat](https://badges.gitter.im/trailblazer/chat.svg)](https://gitter.im/trailblazer/chat)
[![TRB Newsletter](https://img.shields.io/badge/TRB-newsletter-lightgrey.svg)](http://trailblazer.to/newsletter/)
[![Gem Version](https://badge.fury.io/rb/trailblazer.svg)](http://badge.fury.io/rb/trailblazer)
[![Open Source Helpers](https://www.codetriage.com/trailblazer/trailblazer/badges/users.svg)](https://www.codetriage.com/trailblazer/trailblazer)

**This document discusses Trailblazer 2.1.** An overview about the additions are [on our website](http://trailblazer.to/blog/2017-12-trailblazer-2-1-what-you-need-to-know.html).

The [1.x documentation is here](http://trailblazer.to/gems/operation/1.1/).

## Trailblazer In A Nutshell

1. All business logic is encapsulated in [operations](#operation) (service objects).
  * Optional [validation objects](#validation) (Reform and/or Dry-validation) in the operation deserialize and validate input. The form object can also be used for rendering.
  * An optional [policy](#policies) object blocks unauthorized users from running the operation.
  * Optional [callback](#callbacks) objects allow declaring post-processing logic.
3. [Controllers](#controllers) instantly delegate to an operation. No business code in controllers, only HTTP-specific logic.
4. [Models](#models) are persistence-only and solely define associations and scopes. No business code is to be found here. No validations, no callbacks.
5. The presentation layer offers optional [view models](#views) (Cells) and [representers](#representers) for document APIs.

Trailblazer is designed to handle different contexts like user roles by applying [inheritance](#inheritance) between and [composing](#composing) of operations, form objects, policies, representers and callbacks.

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

The file structure is implemented by the [`trailblazer-loader` gem](https://github.com/trailblazer/trailblazer-loader).

[Learn more.](http://trailblazer.to/gems/trailblazer/loader.html)


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
  step :process!

  def process!(options)
    # do whatever you feel like.
  end
end
```

Operations only need to define and implement steps, like the `#process!` steps. Those steps receive the arguments from the caller.

You cannot instantiate them per design. The only way to invoke them is `call`.

```ruby
Song::Create.call(whatever: "goes", in: "here")
# same as
Song::Create.(whatever: "goes", in: "here")
```

Their high degree of encapsulation makes them a [replacement for test factories](#test), too.

[Learn more.](http://trailblazer.to/gems/operation)

### Contract
The Contract Macro, covers the contracts for Trailblazer, they are basically Reform objects that you can define and validate inside an operation. Reform is a fantastic tool for deserializing and validating deeply nested hashes, and then, when valid, writing those to the database using your persistence layer such as ActiveRecord.

```ruby
# app/concepts/song/contract/create.rb
module Song::Contract
  class Create < Reform::Form
    property :title
    property :length

    validates :title,  length: 2..33
    validates :length, numericality: true
  end
end
```

The Contract then gets hooked into the operation. using this Macro.
```ruby
# app/concepts/song/operation/create.rb
class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate()
  step Contract::Persist()
end
```
As you can see, using contracts consists of five steps.

Define the contract class (or multiple of them) for the operation.
Plug the contract creation into the operation’s pipe using Contract::Build.
Run the contract’s validation for the params using Contract::Validate.
If successful, write the sane data to the model(s). This will usually happen in the Contract::Persist macro.
After the operation has been run, interpret the result. For instance, a controller calling an operation will render a erroring form for invalid input.

Here’s what the result would look like after running the Create operation with invalid data.
```ruby
result = Song::Create.( title: "A" )
result.success? #=> false
result["contract.default"].errors.messages
  #=> {:title=>["is too short (minimum is 2 characters)"], :length=>["is not a number"]}
```

#### Build
The Contract::Build macro helps you to instantiate the contract. It is both helpful for a complete workflow, or to create the contract, only, without validating it, e.g. when presenting the form.
```ruby
class Song::New < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
end
```

This macro will grab the model from options["model"] and pass it into the contract’s constructor. The contract is then saved in options["contract.default"].
```ruby
result = Song::New.()
result["model"] #=> #<struct Song title=nil, length=nil>
result["contract.default"]
  #=> #<Song::Contract::Create model=#<struct Song title=nil, length=nil>>
```
The Build macro accepts the :name option to change the name from default.

#### Validation
The Contract::Validate macro is responsible for validating the incoming params against its contract. That means you have to use Contract::Build beforehand, or create the contract yourself. The macro will then grab the params and throw then into the contract’s validate (or call) method.

```ruby
class Song::ValidateOnly < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate()
end
```
Depending on the outcome of the validation, it either stays on the right track, or deviates to left, skipping the remaining steps.
```ruby
result = Song::ValidateOnly.({}) # empty params
result.success? #=> false
```

Note that Validate really only validates the contract, nothing is written to the model, yet. You need to push data to the model manually, e.g. with Contract::Persist.
```ruby
result = Song::ValidateOnly.({ title: "Rising Force", length: 13 })

result.success? #=> true
result["model"] #=> #<struct Song title=nil, length=nil>
result["contract.default"].title #=> "Rising Force"
```

Validate will use options["params"] as the input. You can change the nesting with the :key option.

Internally, this macro will simply call Form#validate on the Reform object.

Note: Reform comes with sophisticated deserialization semantics for nested forms, it might be worth reading a bit about Reform to fully understand what you can do in the Validate step.

##### Key
Per default, Contract::Validate will use options["params"] as the data to be validated. Use the key: option if you want to validate a nested hash from the original params structure.
```ruby
class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate( key: "song" )
  step Contract::Persist( )
end
```

This automatically extracts the nested "song" hash.
```ruby
result = Song::Create.({ "song" => { title: "Rising Force", length: 13 } })
result.success? #=> true
```

If that key isn’t present in the params hash, the operation fails before the actual validation.
```ruby
result = Song::Create.({ title: "Rising Force", length: 13 })
result.success? #=> false
```

Note: String vs. symbol do matter here since the operation will simply do a hash lookup using the key you provided.

#### Persist
To push validated data from the contract to the model(s), use Persist. Like Validate, this requires a contract to be set up beforehand.
```ruby
class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build( constant: Song::Contract::Create )
  step Contract::Validate()
  step Contract::Persist()
end
```

After the step, the contract’s attribute values are written to the model, and the contract will call save on the model.
```ruby
result = Song::Create.( title: "Rising Force", length: 13 )
result.success? #=> true
result["model"] #=> #<Song title="Rising Force", length=13>
```

You can also configure the Persist step to call sync instead of Reform’s save.
```ruby
step Persist( method: :sync )
```
This will only write the contract’s data to the model without calling save on it.

##### Name
Explicit naming for the contract is possible, too.
```ruby

class Song::Create < Trailblazer::Operation
  step Model( Song, :new )
  step Contract::Build(    name: "form", constant: Song::Contract::Create )
  step Contract::Validate( name: "form" )
  step Contract::Persist(  name: "form" )
end
```

You have to use the name: option to tell each step what contract to use. The contract and its result will now use your name instead of default.
```ruby
result = Song::Create.({ title: "A" })
result["contract.form"].errors.messages #=> {:title=>["is too short (minimum is 2 ch...
```

Use this if your operation has multiple contracts.

#### Result Object
The operation will store the validation result for every contract in its own result object.

The path is result.contract.#{name}.
```ruby
result = Create.({ length: "A" })

result["result.contract.default"].success?        #=> false
result["result.contract.default"].errors          #=> Errors object
result["result.contract.default"].errors.messages #=> {:length=>["is not a number"]}
```

Each result object responds to success?, failure?, and errors, which is an Errors object.

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

## Policies

You can abort running an operation using a policy. "[Pundit](https://github.com/elabs/pundit)-style" policy classes define the rules.

```ruby
class Song::Policy
  def initialize(user, song)
    @user, @song = user, song
  end

  def create?
    @user.admin?
  end
end
```

The rule is enabled via the `::policy` call.

```ruby
class Song::Create < Trailblazer::Operation
  step Policy( Song::Policy, :create? )
end
```

The policy is evaluated in `#setup!`, raises an exception if `false` and suppresses running `#process`.

[Learn more.](http://trailblazer.to/gems/operation/policy.html)


## Views

View rendering can happen using the controller as known from Rails. This is absolutely fine for simple views.

More complex UI logic happens in _View Models_ as found in [Cells](https://github.com/apotonick/cells). View models also replace helpers.

The operation's form object can be rendered in views, too.

```ruby
class SongsController < ApplicationController
  def new
    form Song::Create # will assign the form object to @form.
  end
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
class Song::Create < Trailblazer::Operation
  representer do
    # inherited :body
    include Roar::JSON::HAL

    link(:self) { song_path(represented.id) }
  end
end
```

The operation can then parse incoming JSON documents in `validate` and render a document via `to_json`.

[Learn more.](http://trailblazer.to/gems/operation/2.0/representer.html)

## Tests

In Trailblazer, you only have operation unit tests and integration smoke tests to test the operation/controller wiring.

Operations completely replace the need for leaky factories.

```ruby
describe Song::Update do
  let(:song) { Song::Create.(song: {body: "[That](http://trailblazer.to)!"}) }
end
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
gem "trailblazer-cells"
```

Cells is _not_ required per default! Add it if you use it, which is highly recommended.
