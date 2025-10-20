# Contributing to TypedStruct

TypedStruct is written in [Elixir](https://elixir-lang.org).

For branching management, this project uses
[git-flow](https://github.com/petervanderdoes/gitflow-avh). The `main` branch is
reserved for releases: the development process occurs on `develop` and feature
branches. **Please never commit to `main`.**

## Setup

### Local repository

1. Fork the repository.

2. Clone your fork to a local repository:

        git clone https://github.com/you/typed_struct.git
        cd typed_struct

3. Add the main repository as a remote:

        git remote add upstream https://github.com/ejpcmac/typed_struct.git
        git fetch --all

4. Checkout `develop`:

        git checkout develop

### Development environment (with Nix)

1. Install [Nix](https://zero-to-nix.com/start/install):

        curl --proto '=https' --tlsv1.2 -sSf -L \
            https://install.determinate.systems/nix | sh -s -- install

2. Optionally install [direnv](https://github.com/direnv/direnv) to
    automatically setup the environment when you enter the project directory:

        nix profile install "nixpkgs#direnv" "nixpkgs#nix-direnv"

    In this case, you also need to [hook direnv into your
    shell](https://direnv.net/docs/hook.html) by adding to your `~/.<shell>rc`:

    ```sh
    eval "$(direnv hook <shell>)"
    ```

    *Make sure to replace `<shell>` by your shell, namely `bash`, `zsh`, …*

    For the caching mechanism to work, you also need to setup `nix-direnv`:

        mkdir -p $HOME/.config/direnv
        echo "source $HOME/.nix-profile/share/nix-direnv/direnvrc" \
            > $HOME/.config/direnv/direnvrc

3. In the project directory, if you opted to use direnv, please allow the
    `.envrc` by running:

        direnv allow

    direnv will then automatically update your environment to behave like a Nix
    devshell whenever your enter the project directory, making all tools
    available.

    If you **did not** install direnv, you’ll need to manually start a devshell
    each time you enter the project by running:

        nix develop

### Development environment (without Nix)

Install:

* an Elixir toolchain,
* the following linters and formatters:
    * `committed`,
    * `eclint`,
    * `nixpkgs-fmt`,
    * `prettier`,
    * `taplo`,
    * `typos`,
* optionally `git-flow`.

### Checking that everything works

You can build the project and run all CI checks with:

    mix check

All the checks should pass.

## Workflow

To make a change, please use this workflow:

1. Checkout `develop` and apply the last upstream changes (use rebase, not
    merge!):

        git checkout develop
        git fetch --all --prune
        git rebase upstream/develop

2. For a tiny patch, create a new branch with an explicit name:

        git checkout -b <my_branch>

    Alternatively, if you are working on a feature which would need more work,
    you can create a feature branch with `git-flow`:

        git flow feature start <issue_id>-<my_feature>

    *Note: always open an issue and ask before starting a big feature, to avoid
    it not being merged and your time lost.*

3. Work on your feature (don’t forget to write tests):

        # Some work
        git z commit
        # Some work
        git z commit
        ...

4. When your feature is ready, feel free to use
    [interactive rebase](https://help.github.com/articles/about-git-rebase/) so
    your history looks clean and is easy to follow. Then, apply the last
    upstream changes on `develop` to prepare integration:

        git checkout develop
        git fetch --all --prune
        git rebase upstream/develop

5. If there were commits on `develop` since the beginning of your feature
    branch, integrate them by **rebasing** if your branch has few commits, or
    merging if you had a long-lived branch:

        git checkout <my_feature_branch>
        git rebase develop

    *Note: the only case you should merge is when you are working on a big
    feature. If it is the case, we should have discussed this before as stated
    above.*

6. Run the checks to ensure there is no regression and everything works as
    expected:

        mix check

7. If it’s all good, open a pull request to merge your branch into the `develop`
    branch on the main repository.

## Coding style

Please format your code with the following tools:

* Elixir with `mix format`,
* Nix with `nixpkgs-fmt`,
* TOML with `taplo`,
* YAML and JSON with `prettier`.

For Elixir code, please follow [this style
guide](https://github.com/christopheradams/elixir_style_guide).

All contributed code must be documented and functions must have typespecs. In
general, take your inspiration from the existing code.

## Commit style

Please name your commits using [Conventional
Commits](https://www.conventionalcommits.org/en/v1.0.0/) and using the types and
scopes defined in `git-z.toml`. You can use `git z commit` to help you prepare
the commit message.
