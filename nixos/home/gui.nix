{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mongodb-compass # (Unfree, ensure allowUnfree=true)
    localsend
    powertop
    spotify
    steam-run
    appimage-run

    qalculate-qt
    helm-dashboard

    mpv
    yt-dlp
    veracrypt

    discord
    onlyoffice-desktopeditors
  ];
}
