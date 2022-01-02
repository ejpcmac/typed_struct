# Contributing to TypedStruct

TypedStruct is written in [Elixir](https://elixir-lang.org).

For branching management, this project uses
[git-flow](https://github.com/petervanderdoes/gitflow-avh). The `main` branch is
reserved for releases: the development process occurs on `develop` and feature
branches. **Please never commit to `main`.**

You can easily set up a development environment featuring all the dependencies,
including Elixir and `git-flow`, by using [Nix](https://nixos.org/nix/). This is
detailed below.

## Setup

### Local repository

1. Fork the repository.

2. Clone your fork to a local repository:

        $ git clone https://github.com/you/typed_struct.git
        $ cd typed_struct

3. Add the main repository as a remote:

        $ git remote add upstream https://github.com/ejpcmac/typed_struct.git

4. Checkout `develop`:

        $ git checkout develop

### Development environment (without Nix)

Install an Elixir environment, and optionally install `git-flow`.

### Development environment (with Nix)

1. Install Nix by running the script and following the instructions:

        $ curl https://nixos.org/nix/install | sh

2. Optionally install [direnv](https://github.com/direnv/direnv) to
    automatically setup the environment when you enter the project directory:

        $ nix-env -i direnv

    In this case, you also need to add to your `~/.<shell>rc`:

    ```sh
    eval "$(direnv hook <shell>)"
    ```

    *Make sure to replace `<shell>` by your shell, namely `bash`, `zsh`, …*

3. In the project directory, if you **did not** install direnv, start a Nix
   shell:

        $ cd typed_struct
        $ nix-shell

    If you opted to use direnv, please allow the `.envrc` instead of running a
    Nix shell manually:

        $ cd typed_struct
        $ direnv allow

    In this case, direnv will automatically update your environment to behave
    like a Nix shell whenever you enter the project directory.

### Git-flow

If you want to use `git-flow` and use the standard project configuration, please
run:

    $ ./.gitsetup

### Building the project

1. Fetch the project dependencies:

        $ cd typed_struct
        $ mix deps.get

2. Run the static analyzers:

        $ mix check

All the tests should pass.

## Workflow

To make a change, please use this workflow:

1. Checkout `develop` and apply the last upstream changes (use rebase, not
    merge!):

        $ git checkout develop
        $ git fetch --all --prune
        $ git rebase upstream/develop

2. For a tiny patch, create a new branch with an explicit name:

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
        $ git commit -am "feat: my first change"
        # Some work
        $ git commit -am "refactor: my second change"
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

        $ mix check

7. If it’s all good, open a pull request to merge your branch into the `develop`
    branch on the main repository.

## Coding style

Please format your code with `mix format` or your editor and follow
[this style guide](https://github.com/christopheradams/elixir_style_guide).

All contributed code must be documented and functions must have typespecs. In
general, take your inspiration from the existing code.

Please name your commits using [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/)
