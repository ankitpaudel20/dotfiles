{ ... }:
{
  imports = [
    ./devtools.nix
    ./kube.nix
    ./neovim.nix
    ./tools.nix
    ./git.nix
    ./shell.nix
    ./apps.nix
  ];

  programs.home-manager.enable = true;
}
