{ pkgs, ... }:
{
  programs = {
    bat.enable = true;

    eza = {
      enable = true;
      icons = "always";
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    btop.enable = true;

    tmux.enable = true;

    jq.enable = true;

    ripgrep.enable = true;

    zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };

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
    curl
    trash-cli

    # Editors-of-last-resort and TUIs
    lazygit
    lazydocker
    yazi
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
    parallel
    traceroute

    # Data / archive (additional)
    yq-go
    unrar # unfree, allowed via flake's config.allowUnfree
    valkey # provides valkey-cli; no systemd service from HM
    nil
  ];
}
