{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        system = "${system}";

        # Uncomment for nixpkgs configuration
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          dart
          flutter
        ];

        PUB_HOSTED_URL = "https://pub.myket.ir";
        FLUTTER_STORAGE_BASE_URL = "https://pub.myket.ir";

        shellHook = ''
          # Uncomment if you use zsh
          zsh
        '';

      };
    };
}
