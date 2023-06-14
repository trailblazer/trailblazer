# Trailblazer

_Battle-tested Ruby framework to help structuring your business logic._

[![Gem Version](https://badge.fury.io/rb/trailblazer.svg)](http://badge.fury.io/rb/trailblazer)

## What's Trailblazer?

Trailblazer introduces new abstraction layers into Ruby applications to help you structure your business logic.

It ships with our canonical "service object" implementation called *operation*, many conventions, gems for testing, Rails support, optional form objects and much more.

## Should I use Trailblazer?

Give us a chance if you say "yes" to this!

* You hate messy controller code but don't know where to put it?
* Moving business code into the model gives you nightmares?
* "Service objects" are great?
* Anyhow, you're tired of 12 different "service object" implementations throughout your app?
* Additional abstractions such as form objects or policies would be nice to have in big frameworks?

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

The `step` DSL takes away the pain of flow control and error handling. You focus on what happens: creating models, validating data, sending out notifications.

### Control flow

The operation takes care of the flow control. Internally, this works as depicted in this beautiful diagram.

![Flow diagram of a typical operation.](https://github.com/trailblazer/trailblazer/blob/readme/doc/song_operation_create.png?raw=true)

The best part: the only way to invoke this operation is `Operation.call`. The single entry-point saves programmers from shenanigans with instances and has proven to be an almost bullet-proof concept in the past 10 years.

```ruby
result = Song::Operation::Create.(params: {title: nil, band: "Rancid"})

result.success? #=> true
result[:model]  #=> #<Song title="Hear Us Out" ...>
```

Operations encourage a high degree of encapsulation while giving you all the conventions and tools for free except for a bit of a learning curve.

### Tracing

In the past years, we learnt from some old mistakes and improved developer experience. As a starter, check out our built-in tracing!

```ruby
result = Song::Operation::Create.wtf?(params: {title: "Hear Us Out", band: "Rancid"})
```

![Tracing the internal flow of an operation.](https://github.com/trailblazer/trailblazer/blob/readme/doc/song_operation_create_trace.png?raw=true)

## There's a lot more

All our abstraction layers such as operations, form objects, view components, test gems and much more are used in [hundreds of OSS projects](https://github.com/trailblazer/trailblazer/network/dependents) and commercial applications in the Ruby world.

We provide a visual debugger, a BPMN editor for long-running business processes, comprehensive documentation and a growing list of onboarding videos.

## Documentation

* **The current version is Trailblazer 2.1.** We do have [comprehensive API documenation](https://trailblazer.to/2.1/docs/trailblazer.html) ready for you. If you're new to TRB start with our [LEARN page](https://trailblazer.to/2.1/learn.html).
* A migration guide from 2.0 can be found [on our website](https://trailblazer.to/2.1/docs/trailblazer.html#trailblazer-2-1-migration).
* The [1.x documentation is here](http://trailblazer.to/2.0/gems/operation/1.1/index.html).

Make sure to check out the new beginner's guide to learning Trailblazer. The [brand-new book](https://leanpub.com/buildalib) discusses all aspects in a step-wise approach you need to understand Trailblazer's mechanics and design ideas.

<a href="https://leanpub.com/buildalib"><img src="https://trailblazer.to/images/2.1/buildalib-cover.png"></a>

## Screencasts

Watch our series of screencasts [**TRAILBLAZER TALES**](https://www.youtube.com/channel/UCi2P0tFMtjMUsWLYAD1Ezsw) if you prefer learning from videos!

<a href="https://www.youtube.com/embed/9elpobV4HSw"><img src="https://trailblazer.to/images/2.1/01-operation-basics.png"></a>
