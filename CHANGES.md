# 0.3.0

## Changes

* In Railtie, use `ActionDispatch::Reloader.to_prepare` for autoloading, nothing else. This should fix spring reloading.
* Allow `Op#validate(params, model, Contract)` with CRUD.
* Allows prefixed table names, e.g. `admin.users` in `Controller`. The instance variables will be `@user`. Thanks to @fernandes and especially @HuckyDucky.

## API change

1. The return value of #process is no longer returned from ::run and ::call. they always return the operation instance.
2. The return value of #validate is true or false. this allows a more intuitive operation body.

    ```ruby
    def process(params)
      if validate(params)
        .. do valid
      else
        .. handle invalid
      end
    end
    ```

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