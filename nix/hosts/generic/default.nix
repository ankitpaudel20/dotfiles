{ ... }:
let
  user = builtins.getEnv "USER";
  home = builtins.getEnv "HOME";
in
{
  imports = [ ../../home/common/core ];

  programs.home-manager.enable = true;

  home.username =
    if user != "" then
      user
    else
      throw "USER is empty; activate the generic profile with --impure so builtins.getEnv works";
  home.homeDirectory = if home != "" then home else "/home/${user}";
  home.stateVersion = "25.11";
}
