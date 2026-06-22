{ ... }:
{
  imports = [
    ../../home/common
    ../../home/common/arch-overrides.nix
  ];

  home.username = "smloy";
  home.homeDirectory = "/home/smloy";

  # Pin once, never bump casually. Anchors HM's state-format compatibility.
  home.stateVersion = "25.11";

  # Arch starts ssh-agent itself; point clients at its socket. NixOS uses
  # programs.ssh.startAgent which sets SSH_AUTH_SOCK on its own, so this
  # override stays scoped to the smloyarch host.
  programs.zsh.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
}
