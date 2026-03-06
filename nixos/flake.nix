{
  description = "Default";

  inputs = {
    # We use unstable as agreed
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      home-manager,
      plasma-manager,
      ...
    }:
    {
      nixosConfigurations = {
        # REPLACE 'hostname' with your actual hostname (type `hostname` in terminal to check)
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          # Pass inputs to modules so you can use them there
          specialArgs = { inherit inputs; };

          modules = [
            ./configuration.nix

            # Home Manager module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # Pass inputs to home-manager modules too
              home-manager.extraSpecialArgs = { inherit inputs; };

              # REPLACE 'youruser'
              home-manager.users.smloy = import ./home/home.nix;
            }
          ];
        };
      };
    };
}
