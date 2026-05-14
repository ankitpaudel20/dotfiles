{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    rustup

    # Python tooling
    uv
    ruff
    # ruff-lsp removed from nixpkgs — `ruff` provides built-in LSP via `ruff server`

    # Build systems
    cmake
  ];
}
