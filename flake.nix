{
  description = "FHS Environment for Flutter and Android Development";

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
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        # Gradle can't install anything into this read-only SDK, so it must list
        # every version the build asks for: compileSdk of the app and its plugins
        # (34-36), and the NDK and CMake that plugins with native code need.
        androidSdk =
          (pkgs.androidenv.composeAndroidPackages {
            platformVersions = [
              "34"
              "35"
              "36"
            ];
            buildToolsVersions = [ "36.0.0" ];
            includeNDK = true;
            ndkVersions = [ "28.2.13676358" ];
            cmakeVersions = [ "3.22.1" ];
          }).androidsdk;

        fhs = pkgs.buildFHSEnv {
          name = "flutter-fhs-env";

          targetPkgs =
            pkgs: with pkgs; [
              # Core & Shell Utilities
              bash
              coreutils
              which
              git
              curl
              wget
              unzip
              zip
              file
              gnupg

              # Build Toolchain
              gcc
              gnumake
              cmake
              ninja
              pkg-config

              # flutter
              flutter
              dart

              # Java
              jdk17

              # Android Platform Tools (adb)
              android-tools

              # Flutter Desktop & Graphics Libraries
              gtk3
              glib
              pango
              cairo
              gdk-pixbuf
              atk
              harfbuzz
              freetype
              fontconfig
              dbus
              libglvnd
              mesa
              vulkan-loader
              vulkan-headers

              # Audio, Compression & Common C/C++ dependencies
              alsa-lib
              pulseaudio
              zlib
              libsecret
              sqlite
              openssl
            ];

          multiPkgs =
            pkgs: with pkgs; [
              zlib
              glibc
            ];

          profile = ''
            # Set up Android SDK paths
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export ANDROID_USER_HOME="$HOME/.android"
            export JAVA_HOME="${pkgs.jdk17}/lib/openjdk"

            # Point to local official Flutter SDK if extracted in home directory
            if [ -d "$HOME/flutter/bin" ]; then
              export PATH="$HOME/flutter/bin:$PATH"
            fi

            # Add Android CLI & Platform Tools to PATH
            export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

            # Allow Gradle / AGP to find native graphics drivers inside FHS
            export LD_LIBRARY_PATH=/usr/lib:/usr/lib64:$LD_LIBRARY_PATH

            # Flutter Mirros
            # export PUB_HOSTED_URL="https://pub.myket.ir"
            # export FLUTTER_STORAGE_BASE_URL="https://pub.myket.ir"
          '';

          runScript = "zsh";
        };
      in
      {
        devShells.default = fhs.env;
      }
    );
}
