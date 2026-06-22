{
  description = "home-manager config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      mkGeneric =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          modules = [ ./hosts/generic ];
        };
    in
    {
      homeConfigurations = {
        "smloy@smloyarch" = home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs "x86_64-linux";
          modules = [ ./hosts/smloyarch ];
        };

        # Generic Linux profile. Reads $USER and $HOME at activation; requires --impure.
        # Example:
        #   nix run home-manager/master -- switch \
        #     --flake github:ankitpaudel/dotfiles?dir=nix#generic --impure -b pre-hm
        generic = mkGeneric "x86_64-linux";
        generic-aarch64 = mkGeneric "aarch64-linux";
      };

      devShells.x86_64-linux.default = (mkPkgs "x86_64-linux").mkShellNoCC {
        packages = [
          self.formatter.x86_64-linux
          (mkPkgs "x86_64-linux").home-manager
        ];
      };

      formatter.x86_64-linux = (mkPkgs "x86_64-linux").nixfmt-rfc-style;
    };
}
