{ pkgs, ... }:
{
  programs = {
    uv.enable = true;
    go.enable = true;
    ruff.enable = true;
  };
  home.packages = with pkgs; [
    rustup
    # Build systems
    cmake
    claude-code
  ];
}
