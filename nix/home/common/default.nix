{ ... }:
{
  imports = [
    ./core
    ./linux-desktop.nix
  ];

  programs.home-manager.enable = true;
}
