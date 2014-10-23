* allow `Op[{body: "Great!"}, {additional: true}]` to save merge.
* make `Op[]` not require wrap like `comment: {}`
* in tests, make Op[].model return the reloaded model!

* don't pass contract in validate, we have #contract.
* abstract validate/success/fail into methods to make it easily overrideable.