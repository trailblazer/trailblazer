# Trailblazer

_Battle-tested Ruby framework to help structuring your business logic._

[![Gem Version](https://badge.fury.io/rb/trailblazer.svg)](http://badge.fury.io/rb/trailblazer)

## What's Trailblazer?

Trailblazer introduces new abstraction layers into Ruby applications to help you structure your business logic.

It ships with our canonical "service object" implementation called *operation*, many conventions, gems for testing, Rails support, optional form objects and much more.

## Should I use Trailblazer?

Give us a chance if you say "yes" to this!

* You hate messy controller code but don't know where to put it?
* Moving business code into the "fat model" gives you nightmares?
* "Service objects" are great?
* Anyhow, you're tired of 12 different "service object" implementations throughout your app?
* You keep asking for additional layers such as forms, policies, decorators?

Yes? Then we got a well-seasoned framework for you: [Trailblazer](https://trailblazer.to/2.1).

Here are the main concepts.

## Operation

The operation encapsulates business logic and is the heart of the Trailblazer architecture.

An operation is not just a monolithic replacement for your business code. It's a simple orchestrator between the form objects, models, your business code and all other layers needed to get the job done.

```ruby
# app/concepts/song/operation/create.rb
module Song::Operation
  class Create < Trailblazer::Operation
    step :create_model
    step :validate
    left :handle_errors
    step :notify

    def create_model(ctx, **)
      # do whatever you feel like.
      ctx[:model] = Song.new
    end

    def validate(ctx, params:, **)
      # ..
    end
    # ...
  end
end
```

The `step` DSL takes away the pain of flow control and error handling. You focus on _what_ happens: creating models, validating data, sending out notifications.

### Control flow

The operation takes care _when_ things happen: the flow control. Internally, this works as depicted in this beautiful diagram.

![Flow diagram of a typical operation.](https://github.com/trailblazer/trailblazer/blob/readme/doc/song_operation_create.png?raw=true)

The best part: the only way to invoke this operation is `Operation.call`. The single entry-point saves programmers from shenanigans with instances and internal state - it's proven to be an almost bullet-proof concept in the past 10 years.

```ruby
result = Song::Operation::Create.(params: {title: "Hear Us Out", band: "Rancid"})

result.success? #=> true
result[:model]  #=> #<Song title="Hear Us Out" ...>
```

Data, computed values, statuses or models from within the operation run are exposed through the `result` object.

Leveraging those functional mechanics, operations encourage a high degree of encapsulation while giving you all the conventions and tools for free (except for a bit of a learning curve).

### Tracing

In the past years, we learnt from some old mistakes and improved developer experience. As a starter, check out our built-in tracing!

```ruby
result = Song::Operation::Create.wtf?(params: {title: "", band: "Rancid"})
```

![Tracing the internal flow of an operation.](https://github.com/trailblazer/trailblazer/blob/readme/doc/song_operation_create_trace.png?raw=true)

## There's a lot more

All our abstraction layers such as operations, form objects, view components, test gems and much more are used in [hundreds of OSS projects](https://github.com/trailblazer/trailblazer/network/dependents) and commercial applications in the Ruby world.

We provide a visual debugger, a BPMN editor for long-running business processes, comprehensive documentation and a growing list of onboarding videos ([**TRAILBLAZER TALES**](https://www.youtube.com/channel/UCi2P0tFMtjMUsWLYAD1Ezsw)).

Trailblazer is both used for refactoring legacy apps (we support Ruby 2.5+) and helping big teams organizing, structuring and debugging modern, growing (Rails) applications.

## Documentation

* **The current version is Trailblazer 2.1.** We do have [comprehensive API documenation](https://trailblazer.to/2.1/docs/trailblazer.html) ready for you. If you're new to TRB start with our [LEARN page](https://trailblazer.to/2.1/learn.html).
* A migration guide from 2.0 can be found [on our website](https://trailblazer.to/2.1/docs/trailblazer.html#trailblazer-2-1-migration).
* The [1.x documentation is here](http://trailblazer.to/2.0/gems/operation/1.1/index.html).

Make sure to check out the new beginner's guide to learning Trailblazer. The [brand-new book](https://leanpub.com/buildalib) discusses all aspects in a step-wise approach you need to understand Trailblazer's mechanics and design ideas.

![The new begginer's guide.](https://github.com/trailblazer/trailblazer/blob/readme/doc/s_hero.png?raw=true)

