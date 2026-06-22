{ config, lib, ... }:
{
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.home.homeDirectory}/.histfile";
      size = 1000000;
      save = 1000000000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
      findNoDups = true;
      ignoreSpace = true;
    };

    shellAliases = {
      svim = "sudo vim";
      tam = "tmux attach -t main || tmux new -s main";
      la = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    initContent = ''
      # Enable a modern, interactive completion menu you can cycle through with arrow keys
      zstyle ':completion:*' menu select
      setopt HIST_SAVE_NO_DUPS
      setopt autocd extendedglob
      setopt CORRECT

      # Standardize on Emacs map
      bindkey -e

      # Load the native Zsh terminfo database module
      zmodload zsh/terminfo

      # Dynamically bind standard keys using Terminfo
      [[ -n "''${terminfo[khome]}" ]] && bindkey "''${terminfo[khome]}" beginning-of-line
      [[ -n "''${terminfo[kend]}" ]]  && bindkey "''${terminfo[kend]}"  end-of-line
      [[ -n "''${terminfo[kdch1]}" ]] && bindkey "''${terminfo[kdch1]}" delete-char

      # Fallback bindings for Ctrl-modified navigation
      bindkey "^[[1;5D"  backward-word        # Ctrl + Left Arrow
      bindkey "^[[1;5C"  forward-word         # Ctrl + Right Arrow

      # Universal word deletion
      bindkey '^H'          backward-kill-word
      bindkey '\e[127;5u'   backward-kill-word

      [ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"

      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

      source <(kubectl completion zsh)
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # Idempotently add HM's zsh to /etc/shells so `chsh -s ~/.nix-profile/bin/zsh` works
  # on non-NixOS hosts. On NixOS, /etc/shells is managed by the system and this guard
  # turns the hook into a no-op. The grep check makes it a no-op once the line exists.
  home.activation.addNixZshToEtcShells = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e /etc/NIXOS ] && [ -x /usr/bin/sudo ] && [ -x /usr/bin/tee ]; then
      if ! grep -qxF "$HOME/.nix-profile/bin/zsh" /etc/shells 2>/dev/null; then
        echo "Adding $HOME/.nix-profile/bin/zsh to /etc/shells (sudo required)..."
        echo "$HOME/.nix-profile/bin/zsh" | /usr/bin/sudo /usr/bin/tee -a /etc/shells > /dev/null
      fi
    fi
  '';
}
