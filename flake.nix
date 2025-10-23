{
  description = "Typed Elixir structs without boilerplate code.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-z = {
      url = "https://flakehub.com/f/ejpcmac/git-z/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { inputs', ... }:
        let
          pkgs = inputs'.nixpkgs.legacyPackages;
        in
        {
          ######################################################################
          ##                             Packages                             ##
          ######################################################################

          packages = { };

          ######################################################################
          ##                            Devshells                             ##
          ######################################################################

          devshells =
            let
              git-z = inputs'.git-z.packages.git-z;

              buildToolchain = with pkgs; [
                beamMinimal27Packages.elixir_1_18
              ];

              commitCheckToolchain = with pkgs; [
                committed
              ];

              checkToolchain = with pkgs; [
                eclint
                nixpkgs-fmt
                nodePackages.prettier
                taplo
                typos
              ];

              ideToolchain = with pkgs; [
                nixd
              ] ++ lib.optionals stdenv.isLinux [
                libnotify
                inotify-tools
              ] ++ lib.optionals stdenv.isDarwin [
                darwin.apple_sdk.frameworks.CoreFoundation
                darwin.apple_sdk.frameworks.CoreServices
                terminal-notifier
              ];

              developmentTools = [
                git-z
              ];

              ideEnv = [
                {
                  name = "NIX_PATH";
                  value = "nixpkgs=${inputs.nixpkgs}";
                }
                {
                  name = "TYPOS_LSP_PATH";
                  value = "${pkgs.typos-lsp}/bin/typos-lsp";
                }
              ];
            in
            {
              default = {
                name = "typed_struct";

                motd = ''

                  {202}🔨 Welcome to the typed_struct devshell!{reset}
                '';

                packages =
                  buildToolchain
                  ++ commitCheckToolchain
                  ++ checkToolchain
                  ++ ideToolchain
                  ++ developmentTools;

                env =
                  ideEnv;
              };

              ci-committed = {
                name = "typed_struct CI with committed";

                packages =
                  buildToolchain
                  ++ commitCheckToolchain;
              };

              ci-formatters = {
                name = "typed_struct CI with formatters";

                packages =
                  buildToolchain
                  ++ checkToolchain;
              };

              ci-minimal = {
                name = "typed_struct CI minimal";

                packages =
                  buildToolchain;
              };
            };
        };
    };
}
