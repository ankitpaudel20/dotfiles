{ config, lib, ... }:
{
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
      SUDO_EDITOR = "/usr/bin/vim";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    };

    initContent = ''
      setopt HIST_SAVE_NO_DUPS
      setopt autocd extendedglob

      bindkey "^[[1;5D" backward-word
      bindkey "^[[1;5C" forward-word
      bindkey "^[[H"    beginning-of-line
      bindkey "^[[F"    end-of-line
      bindkey "^[[3~"   delete-char
      bindkey "\e[127;5u" backward-kill-word

      generate_python_index_url () {
        : "''${GCP_ARTIFACT_PROJECT:?set GCP_ARTIFACT_PROJECT in ~/.zshenv.local}"
        gcloud auth login
        access_token=$(gcloud auth print-access-token)
        export PYTHON_INDEX_URL="https://oauth2accesstoken:$access_token@us-python.pkg.dev/$GCP_ARTIFACT_PROJECT/packages/simple/"
      }

      [ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"

      export PATH="/opt/google-cloud-cli/bin:$PATH"
      export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

      source <(kubectl completion zsh)

      if [ -f '/home/smloy/google-cloud-sdk/path.zsh.inc' ]; then
        . '/home/smloy/google-cloud-sdk/path.zsh.inc'
      fi
      if [ -f '/home/smloy/google-cloud-sdk/completion.zsh.inc' ]; then
        . '/home/smloy/google-cloud-sdk/completion.zsh.inc'
      fi
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

  # Idempotently add HM's zsh to /etc/shells so `chsh -s ~/.nix-profile/bin/zsh` works.
  # Pacman's zsh package has a post-install hook that does the same; since Nix can't
  # touch /etc on a non-NixOS system, this activation hook bridges that gap. The grep
  # check makes this a no-op once the line exists, so sudo only prompts on the first
  # activation per host.
  home.activation.addNixZshToEtcShells = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! grep -qxF "$HOME/.nix-profile/bin/zsh" /etc/shells 2>/dev/null; then
      echo "Adding $HOME/.nix-profile/bin/zsh to /etc/shells (sudo required)..."
      echo "$HOME/.nix-profile/bin/zsh" | /usr/bin/sudo /usr/bin/tee -a /etc/shells > /dev/null
    fi
  '';
}
