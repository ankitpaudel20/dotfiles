{
  description = "Default";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
