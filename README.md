# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._

In a nutshell: Trailblazer makes you write **logic-less models** that purely act as data objects, don't contain callbacks, nested attributes, validations or domain logic. It **removes bulky controllers** and strong_parameters by supplying additional layers to put that code to and **completely replaces helpers**.

## Mission

While _Trailblazer_ offers you abstraction layers for all aspects of Ruby On Rails, it does _not_ missionize you. Whereever you want, you may fall back to the "Rails Way" with fat models, monolithic controllers, global helpers, etc. This is not a bad thing, but allows you to step-wise introduce Trailblazer's encapsulation in your app without having to rewrite it.

Trailblazer is all about structure. It helps re-organizing existing code into smaller components where different concerns are handled in separated classes. Forms go into form objects, views are object-oriented MVC controllers, the business logic happens in dedicated domain objects backed by completely decoupled persistance objects.

Again, you can pick which layers you want. Trailblazer doesn't impose technical implementations, it offers mature solutions for re-occuring problems in all types of Rails application.

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
│   │   ├── form.rb
│   │   ├── operation.rb
│   │   ├── twin.rb
│   │   ├── persistance.rb
│   │   ├── representer
```

```
│   │   ├── form
│   │   │   ├── admin.rb
```

Files, classes and views that logically belong to one _concept_ are kept in one place. You are free to use additional namespaces within a concept. Trailblazer tries to keep it as simple as possible, though.

## Architecture

1. **Routing** Traiblazer uses Rails routing to map URLs to controllers (we will add simplifications to routing soon).

2. **Controllers** A controller usually contains authentication logic, only (e.g. using devise) and then delegates to an _Enpoint_ or, more often, an _Operation_.  (we will add simplifications to authentication soon)

3. **Endpoint** Endpoints are the only classes with knowledge about HTTP. They delegate to an _Operation_.

4. **Operation** Business logic happens in operations. They replace ActiveRecord callbacks, cleanly group behaviour and encapsulate knowledge about operations like _Create_, _Update_, or _Crop_. Operations can be nested and use other operations.

    An operation uses a _Contract_ to validate the incoming parameters.

5. **Contract** Deserialization of the incoming data, populating an object graph and validating it is done in a _Contract_. This is usually a [reform](https://github.com/apotonick/reform) form which can also be rendered. _Contract_ and _Operation_ both work on the model.

6. **Model** The model can be implemented using any ORM you fancy, for instance [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord#active-record--object-relational-mapping-in-rails) or [Datamapper](http://datamapper.org/).

    In Trailblazer, models are completely empty and solely configure database-relevant directives and associations.

7. **Views** Rendering UI happens in _View Models_ as found in [cells](https://github.com/apotonick/cells). View models also replace helpers.

8. **HTTP API** Consuming and rendering API documents (e.g. JSON or XML) is done via [roar](https://github.com/apotonick/roar) and [representable](https://github.com/apotonick/representable). They usually inherit the schema from <em>Contract</em>s .

9. **Model API** Working with your internal API explicitely is done by using <em>Operation</em>s . <em>Model</em>s should not be accessed directly anymore.

10. **Tests** Subject to tests are mainly <em>Operation</em>s and <em>View Model</em>s , as they encapsulate endpoint behaviour of your app. As a nice side effect, factories are replaced by simple _Operation_ calls.

Trailblazer is basically a mash-up of mature gems that have been developed over the past 10 years and are used in hundreds and thousands of production apps.


## Naming

Concept namespaces with layer names, no AdminController::UserController anymore.


## Routing

Routing in Trailblazer is completely handled by Rails. As forwarding requests to controller actions works just fine, we didn't see a reason to add behaviour here, yet.

There are some enhancements planned, though. See TODO.

## Controllers

A typical controller should contain authentication, authorization and delegations to domain operations. You can leave your controller _configuration_ as it is - with devise, cancan and all the nifty tools. Behaviour should be delegated to `Operation`s.

## Operational Domain Layer: Flow + Operation

### Flow

A Flow invocation implements the pattern of _"Run a piece of code. If true, do this! Else, do that!"_.

## Operation

Operations in Trailblazer aim to implement atomic steps in your application domain like _“Validate and update a comment!”_, _"Run and render a search!"_ or _“Process uploaded images!”_. Operations embrace high-level API calls in your domain: logic that gets invoked from a controller or console.

Operations typically have different granularity levels and will be nested. This could mean that all of the above steps could be run inside a wrapping operation.



### Stateless Operations

Both `Flow` and `Operation` have a single entry point: a class method. While the class method instantly creates an instance and delegates further processing to the latter, this class method stresses the fact that an Operation (with or without a flow) is _stateless_.

Encapsulating an atomic operation into a stateless asset makes it easily detachable, e.g. for background-processing with Sidekiq, Resque or whatever.


### Functional Semantic

Note that "stateless" doesn't mean you're not allowed to mess around with the application state: Internally, you can do whatever you need to meet your domain requirements! The statelessness is refering to the entire Operation and its flow seen from the caller's perspective.

Again, Operations are high-level entry points for your application. With one public method, they expose a rather functional behaviour. This is intended and doesn't break object-orientation at all. Within the operation, you can use as many models, state machines, workflows, etc you need - only the embracing operation is functional.


### Background Processing

One design goal in Trailblazer's operation layer is to make asnynchronous processing a no-brainer. As operations are stateless that is easily achieved: Basically, any operation can be sent to a background process. Trailblazer makes you think in domain operations that come with free background processing. This is completely different to a monolithic model with hundreds of methods and the omnipresent thought of "How to make this part async?".

{Notes: do validation in realtime, send work of Operation to bg}

### Testing Operations

### Operations In Controllers


## Domain
## Persistance
## Views
## Forms
## Contracts
## APIs


## Why?

* Grouping code, views and assets by concepts increases the **maintainability** of your apps. Developers will find their way faster into your structure as the file layout is more intuitive.
* Finding bugs gets less frustrating as encapsulated layers allow **testing components** in total isolation. Once you know your form and your view are ok, it must be the parsing code.
* The reusability of code increases drastically as Trailblazer gently pushes you towards encapsulation. No more redundant helpers but clean inheritance.
* No more surprises from ActiveRecord's massive API. The separation between persistance and domain automatically results in smaller, less destructive APIs for your models.
