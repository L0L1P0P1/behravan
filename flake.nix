{
  description = "Flutter Android development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "13.0";
          buildToolsVersions = [
            "34.0.0"
            "35.0.0"
            "36.0.0"
          ];
          platformVersions = [
            "34"
            "35"
            "36"
          ];
          abiVersions = [
            "arm64-v8a"
            "x86_64"
          ];
          includeNDK = true;
          ndkVersions = [
            "28.2.13676358"
            "27.0.12077973"
          ];
          cmakeVersions = [ "3.22.1" ];
          includeSources = false;
          includeSystemImages = false;
        };

        androidSdk = androidComposition.androidsdk;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.flutter
            pkgs.jdk17
            androidSdk
            pkgs.gradle
          ];

          # PUB_HOSTED_URL = "https://pub.myket.ir";
          # FLUTTER_STORAGE_BASE_URL = "https://pub.myket.ir";

          shellHook = ''
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export JAVA_HOME="${pkgs.jdk17.home}"
            export PATH="$ANDROID_HOME/platform-tools:$PATH"

            # Auto-configure Flutter to recognize the Nix SDK path
            flutter config --android-sdk "$ANDROID_HOME" > /dev/null 2>&1
            zsh
          '';
        };
      }
    );
}
