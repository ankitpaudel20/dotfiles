{
  config,
  pkgs,
  inputs,
  ...
}:
let
  gdk = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components;
    [
      gke-gcloud-auth-plugin
    ]
  );

in
{
  imports = [
    # This connects the plasma-manager input to your home-manager profile
    # inputs.plasma-manager.homeManagerModules.plasma
  ];
  home.packages = with pkgs; [
    qalculate-qt
    k9s
    kubernetes-helm
    helm-dashboard
    gdk
    ghostty
    opencode
    kdePackages.kate
    neovim
    discord
    vlc
    kdePackages.filelight
    kdePackages.kompare
    mongodb-compass # (Unfree, ensure allowUnfree=true)
    postman # (Unfree)

    gemini-cli
    zed-editor-fhs
    code-cursor-fhs
    antigravity-fhs
    localsend

    powertop
    intel-gpu-tools
    spotify
    pear-desktop
    gh

    steam-run
    appimage-run

  ];
  home.shell.enableZshIntegration = true;

  # programs.bash.enable = true;
  programs = {
    chromium = {
      enable = true;
      package = pkgs.brave;
      commandLineArgs = [
        "--disable-features=WaylandWpColorManagerV1"
      ];

    };
    vscode = {
      enable = true;
      package = pkgs.vscode-fhs;
    };
    firefox.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      initContent = ''
        		source <(kubectl completion zsh)
      '';
      shellAliases = {
        vim = "nvim";
      };

    };
    # Enable Starship globally
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        # You can add TOML settings here directly if you want
        add_newline = true;
        kubernetes = {
          style = "bold bright-cyan";
          format = " [kubernetes](italic) [$symbol]($style)";
          symbol = " ";
        };

      };
    };
    # plasma = {
    #   enable = true;

    #   shortcuts = {
    #     # --- Window Management ---
    #     kwin = {
    #       "Window Close" = "Meta+Q";
    #       "Window Maximize" = "Meta+F"; # Toggles Maximize/Restore
    #     };

    #     # --- Applications ---
    #     # Syntax: "services/<desktop-file-name>"."_launch"

    #     # Meta + E for Dolphin
    #     "services/org.kde.dolphin.desktop"."_launch" = "Meta+E";

    #     # Meta + Enter for Terminal
    #     "services/com.mitchellh.ghostty.desktop"."_launch" = "Meta+Return";

    #     # Meta + B for Browser
    #     "services/brave-browser.desktop"."_launch" = "Meta+B";

    #     # --- Unbind Conflicts ---
    #     # We must unbind default KDE shortcuts that steal your keys
    #     plasmashell."manage activities" = [ ]; # Default is Meta+Q
    #     org_kde_powerdevil.powerProfile = [ ]; # Default is Meta+B
    #   };
    # };
  };

  services = {
    kdeconnect.enable = true;
  };
  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "25.11";
}
