# Contributing to TypedStruct

This project uses [git-flow](https://github.com/petervanderdoes/gitflow-avh).
The `master` branch is reserved to releases: the development process occurs on
`develop` and feature branches. **Please never commit to master.**

## Setup

### Local repository

1. Fork the repository

2. Clone your fork to a local repository:

        $ git clone https://github.com/you/typed_struct.git
        $ cd typed_struct

3. Add the main repository as a remote:

        $ git remote add upstream https://github.com/ejpcmac/typed_struct.git

4. Setup `git-flow`:

        $ ./.gitsetup

You should now be on `develop`.

### Development environment

1. Install an Elixir environment.

2. Fetch the project dependencies and build the project:

        $ cd typed_struct
        $ mix do deps.get, compile

3. Launch the tests:

        $ mix test

All the tests should pass.

## Workflow

To make a change, please follow this workflow:

1. Checkout to `develop` and apply the last upstream changes (use rebase, not
    merge!):

        $ git checkout develop
        $ git fetch --all --prune
        $ git rebase upstream/develop

2. Create a new branch with an explicit name:

        $ git checkout -b <my_branch>

    Alternatively, if you are working on a feature which would need more work,
    you can create a feature branch with `git-flow`:

        $ git flow feature start <my_feature>

    *Note: always open an issue and ask before starting a big feature, to avoid
    it not beeing merged and your time lost.*

3. Work on your feature (don’t forget to write typespecs and tests; you can
    check your coverage with `mix coveralls.html` and open
    `cover/excoveralls.html`):

        # Some work
        $ git commit -am "My first change"
        # Some work
        $ git commit -am "My second change"
        ...

4. When your feature is ready, feel free to use
    [interactive rebase](https://help.github.com/articles/about-git-rebase/) so
    your history looks clean and is easy to follow. Then, apply the last
    upstream changes on `develop` to prepare integration:

        $ git checkout develop
        $ git fetch --all --prune
        $ git rebase upstream/develop

5. If there were commits on `develop` since the beginning of your feature
    branch, integrate them by **rebasing** if your branch has few commits, or
    merging if you had a long-lived branch:

        $ git checkout <my_feature_branch>
        $ git rebase develop

    *Note: the only case you should merge is when you are working on a big
    feature. If it is the case, we should have discussed this before as stated
    above.*

6. Run the tests and static analyzers to ensure there is no regression and all
    works as expected:

        $ mix test
        $ mix dialyzer
        $ mix credo

7. If it’s all good, open a pull request to merge your branch into the `develop`
    branch on the main repository.

## Coding style

Please format your code with `mix format` or your editor and follow
[this style guide](https://github.com/christopheradams/elixir_style_guide).

All contributed code must be documented and functions must have typespecs. In
general, take your inspiration in the existing code.
