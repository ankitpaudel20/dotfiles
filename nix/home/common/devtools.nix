{ pkgs, pkgs-unstable, ... }:
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
    pkgs-unstable.claude-code
    postman
  ];
}
