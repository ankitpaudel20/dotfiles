{ ... }:
{
  imports = [ ../../home ];

  home.username = "smloy";
  home.homeDirectory = "/home/smloy";

  # Pin once, never bump casually. Anchors HM's state-format compatibility.
  home.stateVersion = "25.11";
}
