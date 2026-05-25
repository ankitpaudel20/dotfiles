{ inputs, pkgs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager
    ../../nix/home/common
    ./plasma-config.nix
    ./vscode.nix
    ./zeditor.nix
    ./browser.nix
    ./kde-extras.nix
    ./gcloud.nix
    ./gui.nix
  ];

  home.stateVersion = "26.05";

  # python314 doesn't warrant its own module yet — single package.
  home.packages = [ pkgs.python314 ];
}
