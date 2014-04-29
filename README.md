# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces encapsulation, an intuitive code structure and gives you an object-oriented architecture._


## Mission

While _Trailblazer_ offers you abstraction layers for all aspects of Ruby On Rails, it does _not_ missionize you. Whereever you want, you may fall back to the "Rails Way" with fat models, monolithic controllers, helpers, etc. This is not a bad thing, but allows you to step-wise introduce Trailblazer's encapsulation in your app without having to rewrite it.

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
│   │   ├── twin.rb
│   │   ├── persistance.rb
│   │   ├── representer
```

```
│   │   ├── form
│   │   │   ├── admin.rb
```

## Gems

Trailblazer is basically a mash-up of mature gems that have been developed over the past 8 years and are used in hundreds and thousands of production apps.

* Cells for view components
* Reform * Virtus for coercion and Reform::Contract
* Representable
* Roar
* Disposable::Twin
* ActiveRecord, or whatever you fancy as an ORM. (EMPTY data models)
* controller Operation


## Routing

Routing in Trailblazer is completely handled by Rails. As forwarding requests to controller actions works just fine, we didn't see a reason to add behaviour here, yet.

## Controllers

A typical controller should contain authentication, authorization and delegations to domain operations. You can leave your controller _configuration_ as it is - with devise, cancan and all the nifty tools. Behaviour should be delegated to `Operation`s.

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
