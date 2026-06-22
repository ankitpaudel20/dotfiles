{ pkgs, ... }:
{
  programs.foot.enable = true;

  home.packages = with pkgs; [
    xclip
    wl-clipboard
    wtype
    ueberzugpp
  ];
}
