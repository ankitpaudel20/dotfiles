# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

  ];

  fileSystems."/swap" = {
    device = "/dev/nvme0n1p3";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "noatime"
    ];
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  nix.settings = {
    # Increase the number of parallel downloads
    max-jobs = "auto";
    http-connections = 50;
    auto-optimise-store = true;
    max-substitution-jobs = 128;
    substituters = [ "https://cache.nixos.org" ];
    fallback = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];

  };
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = false;
        configurationLimit = 10;
        extraEntries = ''
          menuentry "Arch Linux" --class arch --id arch-linux {
              insmod part_gpt
              insmod btrfs
              search --no-floppy --fs-uuid --set=root 296eabae-1142-4449-9d2d-016c21484194
              configfile /@/boot/grub/grub.cfg
          }
        '';
      };
    };
    # kernelParams = [
    #   "i915.force_probe=!7d55" # Block i915 from grabbing the GPU (7d55 is the ID for Ultra 7 155H)
    #   "xe.force_probe=7d55" # Force xe to grab it
    # ];
    extraModprobeConfig = "options kvm_intel nested=1";
    kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  networking = {
    hostName = "swift-go"; # Define your hostname.

    # Enable networking
    networkmanager.enable = true;

  };
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  # Set your time zone.
  time.timeZone = "Asia/Kathmandu";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services = {

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;

    # Enable CUPS to print documents.
    printing.enable = false;

    # Enable sound with pipewire.
    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

  };
  security.rtkit.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.smloy = {
    isNormalUser = true;
    description = "smloy";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
      "docker"
      "libvirtd"
    ];
  };

  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat

        # Common system libs
        libxml2
        libz
        util-linux
        glib
        gtk3
        gtk4
        pango
        cairo
        gdk-pixbuf
        freetype
        fontconfig

        # Graphics
        libGL
        vulkan-loader
        mesa
      ];
    };
    kdeconnect.enable = true;
    ssh.startAgent = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      # The "Magic" History Config for ALL users
      interactiveShellInit = ''
        export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=black,bold'

        # Initialize Starship explicitly for global users (like root) if not using home-manager
        # eval "$(starship init zsh)"

        # History Settings
        export HISTFILE="$HOME/.histfile"
        export HISTSIZE=50000
        export SAVEHIST=50000

        # Zsh Options
        setopt SHARE_HISTORY          # Share history between all open terminals
        setopt HIST_IGNORE_DUPS       # Don't record same command twice in a row
        setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries from history
        setopt HIST_REDUCE_BLANKS     # Remove useless whitespace
        setopt INC_APPEND_HISTORY     # Write to history file immediately, not when shell exits
      '';
    };
    fzf = {
      fuzzyCompletion = true; # Enables **<TAB> completion
      keybindings = true; # Enables Ctrl-r, Alt-c, etc.
    };
    virt-manager.enable = true;
    git.enable = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Prefer the modern iHD backend
    NIXOS_OZONE_WL = "1";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gparted
    ddccontrol
    lm_sensors
    btrfs-progs
    ntfs3g
    kdePackages.sddm-kcm
    wl-clipboard
    wayland-utils
    qemu
    virtiofsd
    # CLI Utilities
    gcc
    nixfmt
    nvi

  ];

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
