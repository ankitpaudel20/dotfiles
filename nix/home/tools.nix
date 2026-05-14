{ pkgs, ... }:
{
  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    icons = "always";
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.btop.enable = true;

  programs.tmux.enable = true;

  programs.jq.enable = true;

  programs.ripgrep.enable = true;

  home.packages = with pkgs; [
    fastfetch
    croc
    dive
    aria2
    ngrok

    # System / disk / processes
    htop
    ncdu
    tree

    # Editors-of-last-resort and TUIs
    lazygit
    lazydocker
    yazi
    zellij
    nushell
    ueberzugpp

    # Clipboards / Wayland helpers
    xclip
    wl-clipboard
    wtype

    # Text / archive / misc utilities
    bc
    dos2unix
    figlet
    wget
    unzip
    qpdf
    tesseract
    unar
    graphviz

    # Network probes / system info
    arp-scan
    inxi
    trash-cli
    parallel
    traceroute

    # Data / archive (additional)
    yq-go
    unrar     # unfree, allowed via flake's config.allowUnfree
    valkey    # provides valkey-cli; no systemd service from HM
  ];
}
