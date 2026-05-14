{ ... }:
{
  imports = [
    ./languages.nix
    ./kube.nix
    ./neovim.nix
    ./tools.nix
    ./git.nix
    ./shell.nix
  ];

  programs.home-manager.enable = true;
}
