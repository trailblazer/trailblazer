# Trailblazer

_Trailblazer is a thin layer on top of Rails. It gently enforces object-oriented encapsulation and code structure._


It is non-intrusive, allowing you to fallback to the "Rails Way" whenever you want but offers you abstraction layers for all aspects of Ruby On Rails.



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

Trailblazer is basically a mash-up of mature gems that have been developed over the past 8 years and are heavily used in the community.

* Cells for view components
* Reform * Virtus for coercion and Reform::Contract
* Representable
* Roar
* Disposable::Twin
* ActiveRecord, or whatever you fancy as an ORM. (EMPTY data models)



## Why?

* Grouping code, views and assets by concepts increases the **maintainability** of your apps. Developers will find their way faster into your structure as the file layout is more intuitive.
* Finding bugs gets less frustrating as encapsulated layers allow **testing components** in total isolation. Once you know your form and your view are ok, it must be the parsing code.
* The reusability of code increases drastically as Trailblazer gently pushes you towards encapsulation. No more redundant helpers but clean inheritance.
* No more surprises from ActiveRecord's massive API. The separation between persistance and domain automatically results in smaller, less destructive APIs for your models.
