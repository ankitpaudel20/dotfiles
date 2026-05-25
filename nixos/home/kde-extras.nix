{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kdePackages.filelight
    kdePackages.kompare
  ];
}
