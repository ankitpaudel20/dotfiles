{
  description = "Default";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Pinned to the last revision before nixpkgs bumped google-cloud-sdk's
    # bundled python 3.12 -> 3.14 (2026-05-27), which broke its build
    # (auto-patchelf can't satisfy libpython3.14.so.1.0 / libtcl9*.so).
    # Drop this once the 3.14 bundle builds again upstream.
    nixpkgs-gcloud.url = "github:nixos/nixpkgs/64c08a7ca051951c8eae34e3e3cb1e202fe36786";
    claude-code.url = "github:sadjow/claude-code-nix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      claude-code,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      # Each subdirectory under ./hosts becomes a nixosConfiguration named after the directory.
      # The directory must contain a configuration.nix.
      hostNames = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          inherit system;

          # Pass inputs to modules so you can use them there
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/${name}/configuration.nix

            # Override pkgs.claude-code with the always-current build from
            # sadjow/claude-code-nix. Applied to the system nixpkgs so it also
            # reaches home-manager (useGlobalPkgs = true), where the shared
            # devtools.nix module installs `claude-code`.
            { nixpkgs.overlays = [ claude-code.overlays.default ]; }

            # Home Manager module
            home-manager.nixosModules.default
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                # Pass inputs to home-manager modules too
                extraSpecialArgs = { inherit inputs pkgs-unstable; };

                users.smloy = import ./home;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs hostNames mkHost;

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          self.formatter.${system}
          pkgs.home-manager
        ];
      };
      formatter.${system} = pkgs.nixfmt;

    };
}
