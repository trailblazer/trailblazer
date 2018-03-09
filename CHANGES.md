# 2.1

* Macros now always have to provide an `:id`. This was a bit fuzzy in 2.0.

* Nested
  if Nested( Edit ), outputs will automatically be connected, see editor.
* Wrap
  dropped the `pipe` option. This is now `options, flow_options, *`
  `false` is now automatically connected to End.failure.
* remove `Uber::Callable`.

* `operation.new` step removed.
* Undocumented step behavior removed. You can't write to `self` anymore.

        ```ruby
        step :process
        def process(*)
          self["x"] = true
        end
        ```

    Always write to `options`.

* self[] removed
* Fixed `Guard` where procs could receive one argument, only. Guards follow the step interface: `Policy::Guard( ->(options, **) { .. } )
* Removed `Operation::Callback` which was a poor idea and luckily no one was using it.

TODO:
document Task API and define step API
deprecate step->(options) ?
injectable, per-operation step arguments strategy?

# 2.1.0.beta5

* All macros are now cleanly extracted to `trailblazer-macro` and `trailblazer-macro-contract`.

# 2.1.0.beta4

* Simple maintenance release to establish `activity-0.5.0`.

# 2.1.0.beta3

* More simplifications because of `activity`.

# 2.1.0.beta2

* Simplify `Nested` and several other internals by using the new `Activity` API.

# 2.1.0.beta1

* Add `deprecation/call` and `deprecation/context` that help with the new `call` API and symbols for `options` keys.

# 2.0.7

* Allow to use any method with the Model macro, e.g.

    ```ruby
    step Model( Comment, :[] )
    ```

  will now invoke `Comment[ params[:id] ]`, which makes using Sequel a breeze.

# 2.0.6

* Fix what we broke in 2.0.5, where `Wrap` would always use the current operation subclass and not the empty `Trailblazer::Operation`. Thanks to @mensfeld.

# 2.0.5

* In Wrap, use `self` instead of a hard class reference. This allows using Wrap in the compat gem.

# 2.0.4

* When using `Nested(X)`, the automatic `:name` option is now `"Nested(X)"` instead of the cryptic proc string.

# 2.0.3

* `Guard` now allows kw args for its option.
* Fix a bug where `Nested( ->{} )` wouldn't `_call` the nested operation and did too much work on re-nested the already nested params. Thanks to @eliranf for spotting this.
* Add `Nested(..., input: )` to dynamically decide the input to the nested operation. http://trailblazer.to/gems/operation/2.0/api.html#nested-input
* Add `Nested(..., output: )`: http://trailblazer.to/gems/operation/2.0/api.html#nested-output

# 2.0.2

* Remove `uber` dependency as we use our own `Option::KW` now.
* In `Contract::Build( builder: )` you now also have access to the `name:` keyword. Note that you need to double-splat in builders.

        ```ruby
        Contract::Build( builder: ->(options, constant:, **) )
        ```
  Same for `:method` and `Callable`.
* `Policy::Guard( :method )` now works.

# 2.0.1

* Add `fail_fast: true` for `step` and `failure` to short-circuit the pipe. Note that more "eloquent" semantics are coming in `trailblazer-bpmn`.
* Add `fail!`, `fail_fast!`, `pass!`, and `pass_fast!`. Note that they are all experimental API and not documented, yet.
* Remove Builder and allow [dynamic `Nested`](http://trailblazer.to/gems/operation/2.0/api.html#nested-callable).

    ```ruby
    step Nested( ->(options, params:) { params[:type] == "moderated" ? Moderated : Comment } )
    ```
* Remove `override` in favor of `step .., override: true`. Note that this method wasn't documented.
* Numerous internal simplifications [documented here](https://github.com/trailblazer/trailblazer-operation/blob/master/CHANGES.md#0010).


# 2.0.0

All old semantics will be available via [trailblazer-compat](https://github.com/trailblazer/trailblazer-compat).

* Removed `Operation::run` as it was a bad decision. Raising an exception on invalid is a very test-specific scenario and shouldn't have been handled in the core doce.
* Removed `Operation::present`, since you can simply call `Operation::new` (without builders) or `Operation::build_operation` (with builders).
* Removed `Operation::valid?`. This is in the result object via `result.success?`.
* Removed `Operation#errors`. This is in the result object via `result[:errors]` if the operation was invalid.
* Removed the private option `:raise_on_invalid`. Use `Contract::Raise` instead, if you need it in tests.

* Removed `Operation::contract` (without args). Please use `Operation::["contract.default.class"]`.
* Removed `Operation::callbacks` (without args). Please use `Operation::["callback.<name>.class"]`.
* Removed `Operation::contract_class`. Please use `Operation::["contract.default.class"]`.
* Removed `Operation::contract_class=`. Please use `Operation::["contract.default.class"]=`. Doesn't inherit.

## Model

* The `model` method doesn't exist anymore, use `self["model"]` or write your own.
* `:find_by` diverts to left track.
* `:create` is `:new` now.

## Builder

* It's `include Builder` now, not `extend Builder`.
* `builds` now receives one options hash.

## Policy

* No exception anymore, but `Operation#["policy.result"]`.
* Access the current user via `self["current_user"]` now.
* `Policy` is `Policy::Pundit` now as `Policy` is Trailblazer's (upcoming) authorization style.

## Representer

* Removed `Operation::representer_class`. Please use `Operation::["representer.class"]`.
* Removed `Operation::representer_class=`. Please use `Operation::["representer.class"]=`.
* You can now have any number of named representers: `Operation.representer :parser, ParsingRepresenter`.
* Automatic infering of the representer from a `contract` is not so automatic anymore. This feature was barely used and is now available via `include Representer::InferFromContract`.
* Reform 2.0 is not supported in `Representer` anymore, meaning you can't automatically infer representers from 2.0 contracts. Reform 2.0 works with all remaining components.
* Removed `Operation::contract_class`. Please use `Operation::["contract.default.class"]`.
* Removed `Operation::contract_class=`. Please use `Operation::["contract.default.class"]=`. Doesn't inherit.

## Callback

* Removed `Operation::Dispatch`, it's called `Operation::Callback`.


## Collection

* Removed `Operation::Collection`. Please use `Operation::present`.

## Controller

* Removed `Controller`, this is now in [trailblazer-rails](https://github.com/trailblazer/trailblazer-rails/).

## Contract

* You can't call `Create.().contract` anymore. The contract instance(s) are available through the `Result` object via `["contract.default"]`.
* Removed the deprecation for `validate`, signature is `(params[, model, options, contract_class])`.
* Removed the deprecation for `contract`, signature is `([model, options, contract_class])`.

# 2.0.0.rc1

* `consider` got removed since `step` now evaluates the step's result and deviates (or not).

# 2.0.0.rc2

* It's now Contract::Persist( name: "params" ) instead of ( name: "contract.params" ).

# 2.0.0.beta3

* New, very slick keyword arguments for steps.

# 2.0.0.beta2

* Removed `Operation::Controller`.
* Renamed `Persist` to `Contract::Persist`.
* Simplify inheritance by introducing `Operation::override`.
* `Contract` paths are now consistent.

# 2.0.0.beta1

* Still undefined `self.~`.

# 1.1.2

* Stricter `uber` dependency.

# 1.1.1

* Rename `Operation::Representer::ClassMethods` to `Operation::Representer::DSL` and allow to use `DSL` and `Rendering` without `Deserialization` so you can use two different representers.
* `Policy::Guard::policy` now also accepts a `Callable` object.
* Add `Operation#model=`.

# 1.1.0

* `Representer#represented` defaults to `model` now, not to `contract` anymore.
* The only way to let Trailblazer pass a document to the operation is via `is_document: true`. There is _no guessing_ anymore based on whether or not `Representer` is mixed into the operation or not.
* Add `Operation#params!` that works exactly like `#model!`: return another params hash here if you want to change the `params` structure while avoiding modifying the original one.
* Add `Controller#params!` that works exactly like `Operation#params!` and allows returning an arbitrary params object in the controller. Thanks to @davidpelaez for inspiration.
* Deprecate `Dispatch` in favor of `Callback`. In operations, please include `Operation::Callback`. Also, introduced `Operation#callback!` which aliases to `#dispatch!`. Goal is having to think less, and now all naming is in line.

## Fixes

* `Representer#to_json` now allows passing options.
* The `:params` key never got propagated to `prepopulate!` when using `Controller#form`. This is now fixed.

# 1.0.4

* Fix `Controller#run`, which now returns the operation instance instead of the `Else` object.

# 1.0.3

* Remove unprofessional `puts`, @smathy.

# 1.0.2

* Treat all requests as `params` requests unless the operation has a representer mixed in. If you don't want that, you can override using `is_document: false`. This appears to be the smoothest solution for all.
* In `Controller#form`, the options argument is now passed into `form.prepopulate!(options)`. This allows to use arbitrary options and the `options[:params]` for prepopulation.

# 1.0.1

* Treat `:js` requests as non-document, too.
* `Controller#form` now returns the form object and not the operation.
* In `Controller`, `#form`, `#present`, `#run` and `#respond` now all have the same API: `run(constant, options)`. If you want to pass a custom params hash, use `run Comment::Create, params: {..}`.

# 1.0.0

* All Rails-relevant files are now in the `trailblazer-rails` gem. You have to include it should you be in a Rails environment.
* `Operation[{..}]` is deprecated in favor of `Operation.({..})`.
* `Operation::CRUD` is now `Operation::Model`.
* `Controller#form` now invokes `#prepopulate!` before rendering the view.
* `Controller#present` does not instantiate and assign `@form` anymore.
* The internal `Operation` API has changed from `#initialize()` and `#run(params)` to `#initialize(params)` and `#run`.

# 0.3.4

* Added `Operation::Policy`.
* Added `Operation::Resolver`.

# 0.3.3

* Add `Operation::reject` which will run the block when _invalid_.
* In the railtie, require `trailblazer/autoloading` as I am assuming Rails users want maximum comfort.

# 0.3.2

* Allow to use `#contract` before `#validate`. The contract will be instantiated once per `#run` using `#contract` and then memoized. This allows to add/modify the contract _before_ you validate it using `#validate`.
* New signature for `Operation#contract_for(model, contract_class)`. It used to be contract, then model.

# 0.3.1

* Autoload `Dispatch`.

# 0.3.0

## Changes

* In Railtie, use `ActionDispatch::Reloader.to_prepare` for autoloading, nothing else. This should fix spring reloading.
* Allow `Op#validate(params, model, Contract)` with CRUD.
* Allows prefixed table names, e.g. `admin.users` in `Controller`. The instance variables will be `@user`. Thanks to @fernandes and especially @HuckyDucky.
* Added `Operation::Collection` which will allow additional behavior like pagination and scoping. Thanks to @fernandes for his work on this.
* Added `Operation::collection` to run `setup!` without instantiating a contract. This is called in the new `Controller#collection` method.
* Added `Operation#model` as this is a fundamental concept now.
* Improved the undocumented `Representer` module which allows inferring representers from contract, using them to deserialize documents for the form, and rendering documents.
* Changed `Operation::Dispatch` which now provides imperative callbacks.

## API change

1. The return value of #process is no longer returned from ::run and ::call. They always return the operation instance.
2. The return value of #validate is `true` or `false`. This allows a more intuitive operation body.

    ```ruby
    def process(params)
      if validate(params)
        .. do valid
      else
        .. handle invalid
      end
    end
    ```

* `Worker` only works with Reform >= 2.0.0.

# 0.2.3


# 0.2.2

# Added Operation#errors as every operation maintains a contract.

# 0.2.1

* Added `Operation#setup_model!(params)` that can be overridden to add nested objects or process models right after `model!`. Don't add deserialization logic here, let Reform/Representable do that.
* Added `Operation#setup_params!(params)` to normalize parameters before `#process`. Thanks to @gogogarrett.
* Added `Controller::ActiveRecord` that will setup a named controller instance variable for your operation model. Thanks @gogogarrett!
* Added `CRUD::ActiveModel` that currently infers the contract's `::model` from the operation's model.

# 0.2.0

## API Changes

* `Controller#present` no longer calls `respond_to`, but lets you do the rendering. This will soon be re-introduced using `respond(present: true)`.
* `Controller#form` did not respect builders, this is fixed now.
* Use `request.body.read` in Unicorn/etc. environments in `Controller#respond`.

## Stuff

* Autoloading changed, again. We now `require_dependency` in every request in dev.

# 0.1.3

* `crud_autoloading` now simply `require_dependency`s model files, then does the same for the CRUD operation file. This should fix random undefined constant problems in development.
* `Controller#form` did not use builders. This is fixed now.

# 0.1.2

* Add `crud_autoloading`.

# 0.1.1

* Use reform-1.2.0.

# 0.1.0

* First stable release after almost 6 months of blood, sweat and tears. I know, this is a ridiculously brief codebase but it was a hell of a job to structure everything the way it is now. Enjoy!
