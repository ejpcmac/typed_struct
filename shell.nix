{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  erlangDrv = { mkDerivation }:
    mkDerivation rec {
      version = "21.0";
      # Use `nix-prefetch-github --rev OTP-<version> erlang otp` to update.
      sha256 = "0khprgawmbdpn9b8jw2kksmvs6b45mibpjralsc0ggxym1397vm8";

      prePatch = ''
        substituteInPlace configure.in --replace '`sw_vers -productVersion`' '10.10'
      '';
    };

  elixirDrv = { mkDerivation }:
    mkDerivation rec {
      version = "1.7.3";
      # Use `nix-prefetch-github --rev v<version> elixir-lang elixir` to update.
      sha256 = "0d7rj4khmvy76z12njzwzknm1j9rhjadgj9k1chjd4gnjffkb1aa";
      minimumOTPVersion = "19";
    };

  erlang = (beam.lib.callErlang erlangDrv { wxGTK = wxGTK30; }).override {
    # Temporary fix to enable use on OS X El Capitan.
    enableKernelPoll = if stdenv.isDarwin then false else true;
  };

  rebar = pkgs.rebar.override { inherit erlang; };

  elixir = beam.lib.callElixir elixirDrv {
    inherit erlang rebar;
    debugInfo = true;
  };
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
