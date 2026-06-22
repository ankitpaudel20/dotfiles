{ ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = false;
    vimAlias = true;
    defaultEditor = false;
    withRuby = false;
    withPython3 = false;
  };
}
