{
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}:
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
    ./python.nix
  ];

  home.stateVersion = "26.05";
}
