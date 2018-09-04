{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  erlang = beam.interpreters.erlangR21.override {
    # Temporary fix to enable use on OS X El Capitan.
    enableKernelPoll = if stdenv.isDarwin then false else true;
  };

  elixir = (beam.packages.erlangR21.override { inherit erlang; }).elixir_1_7;
in

mkShell {
  buildInputs = [ elixir git ]
    ++ optional stdenv.isLinux libnotify # For ExUnit Notifier on Linux.
    ++ optional stdenv.isDarwin terminal-notifier # For ExUnit Notifier on macOS.
    ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
      # For file_system on macOS.
      CoreFoundation
      CoreServices
    ]);
}
