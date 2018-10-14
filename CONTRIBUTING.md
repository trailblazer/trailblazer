# Contributing to Trailblazer
Trailblazer is an open source project and we would love you to help us make it better.

## Questions/Help
If our [guides][guides] nor [docs][api-docs] can help you figure things out, and you're stuck, refrain from posting questions on github issues, and please just find us on the [trailblazer gitter chat][chat] and drop us a line.

Keep in mind when asking questions though, an example will get you help faster than anything else you do.

If you file an issue with a question, it will be closed. We're not trying to be mean, don't get us wrong, we're just trying to stay sane.

## Reporting Issues
A well formatted issue is appreciated, and goes a long way in helping us help you.

* Make sure you have a [GitHub account](https://github.com/signup/free)
* Submit a [Github issue][issues-link] by:
  * Clearly describing the issue
    * Provide a descriptive summary
    * Provide sample code where possible (preferably in the form of a test, in a [Gist][gist] for bonus points)
    * Explain the expected behavior
    * Explain the actual behavior
    * Provide steps to reproduce the actual behavior
    * Provide your application's complete `Gemfile.lock` as text (in a [Gist][gist] for bonus points)
    * Any relevant stack traces

If you provide code, make sure it is formatted with the triple backticks (\`).

At this point, we'd love to tell you how long it will take for us to respond, but we just don't know.

## Pull requests
We accept pull requests to Trailblazer for:

* Adding documentation
* Fixing bugs
* Adding new features

Not all features proposed will be added but we are open to having a conversation about a feature you are championing.

###Here's a quick guide:
#### Fork the Project
Fork the [project repository][project-repo-link] on Github and check out your copy.

```
git clone https://github.com/YOUR_HANDLE/trailblazer.git
cd trailblazer
git remote add upstream https://github.com/trailblazer/trailblazer.git
```

#### Create a Topic Branch
Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.
```
git checkout master
git pull upstream master
git checkout -b my-feature-branch
```

#### Bundle and Test
Run bundle install/update to gather any and all dependencies. Run the tests. This is to make sure your starting point works.

```
bundle install
bundle exec rake
```

#### Write Tests
Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build. Add to [test][test-link].

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

#### Write Code
Implement your feature or bug fix.

Ruby style is enforced with [RuboCop](https://github.com/bbatsov/rubocop), run `bundle exec rubocop` and fix any style issues highlighted.

Make sure that `bundle exec rake` completes without errors.

#### Write Documentation
Document any external behavior in the [README](README.md).

#### Commit Changes
Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what has changed and why, but be brief.

```
git add your_filename.rb (File names to add content from, or fileglobs e.g. *.rb)
git commit
```

#### Push
```
git push origin my-feature-branch
```

#### Make a Pull Request
Go to https://github.com/YOUR_GH_HANDLE/trailblazer and select your feature branch. Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days, but no need to rush us if it takes longer.

#### Rebase
If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

#### Update CHANGELOG Again
Update the [CHANGELOG](CHANGELOG.md) with the pull request number. A typical entry looks as follows.

```
* [#123](https://github.com/trailblazer/trailblazer/pull/123): Your brief description - [@your_gh_handle](https://github.com/your_gh_handle).
```

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

#### Check on Your Pull Request
Go back to your pull request after a few minutes and see whether it passed muster with Travis-CI. Everything should look green, otherwise fix issues and amend your commit as described above.

## Quality

Committing to OSS projects is always difficult, because all maintainers will adhere to their own quality standards that you don't know. Every projects wants "good code design", and so do we, so here are a few things that you should follow when contributing.

* Good design matters: sometimes a feature could be added with a simple `if <my new case>` to an existing block of code. Usually, an `if` implies that the original design didn't plan on handling multiple cases, or in other words, **a refactoring of the code structure might be necessary**. If you're unsure: [Talk to us!](https://gitter.im/trailblazer/chat)
* Make smaller pull requests. It is so much easier to discuss something graspable and not a "37 files changed" PR. The sooner we see your code, the earlier we can decide about which way to go. It is incredibly appreciated, though, to send us a link to a branch of yours where we can see the desired changes in total. We can then help splitting those into smaller steps.
* **Never ever use `if respond_to?`** to add a feature. This is a pattern as seen a lot in Rails core that causes incredibly hard to find ~bugs~ behavior. In Trailblazer, we use "Tell, don't ask!", which means, never try to find out the type of an object via `respond_to?`. If you really have to introspect the type, use `is_a?`. Treat it as a duck, ducks don't speak.


## Releasing

When you have release rights, please follow these rules.

* When tagging a commit for a release, use the format `vX.X.X` for the tag, e.g. `git tag v2.1.0`.
* The tagged commit **must contain the line** "Releasing vX.X.X" so it can be quickly spotted later in the commit list.

#### What now?
At this point you're waiting on us. Expect a conversation regarding your pull request; Questions, clarifications, and so on.

Some things that will increase the chance that your pull request is accepted:
* Use Trailblazer idioms and follow the Trailblazer ideology
* Include tests that fail without your code, and pass with it
* Update the documentation, guides, etc.

## What do we need help with?
### Helping others!
There are a lot of questions from people as they get started using Trailblazer. If you could **please do the following things**, that would really help:

- Hang out on [the chat][chat]
- Watch the [trailblazer repositories][repositories] for issues or requests that you could help with

### Contributing to community
- Create Macros!
- Write blog posts!
- Record screencasts
- Write examples.

### Contributing to the core
- Tests are always helpful!
- Any of the issues in GitHub, let us know if you have some time to fix one.

## Thank You
Please do know that we really appreciate and value your time and work.

[gist]: https://gist.github.com
[guides]: https://www.trailblazer.to
[api-docs]: https://www.trailblazer.to/api-docs
[chat]: https://gitter.im/trailblazer/chat
[repositories]: https://github.com/trailblazer
[test-link]: https://github.com/trailblazer/trailblazer/tree/master/test
[project-repo-link]: https://github.com/trailblazer/trailblazer
[issues-link]: https://www.github.com/trailblazer/trailblazer/issues
