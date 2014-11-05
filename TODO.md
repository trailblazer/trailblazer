# Operation: External API

* allow `Op[{body: "Great!"}, {additional: true}]` to save merge.
* make `Op[]` not require wrap like `comment: {}`
* in tests, make Op[].model return the reloaded model!

# Operation: Internal API

* don't populate the form in #present context, we don't need it (only the representer goes nuts)
* don't pass contract in validate, we have #contract.
* abstract validate/success/fail into methods to make it easily overrideable.