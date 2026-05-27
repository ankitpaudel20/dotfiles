{ pkgs, ... }:
{
  home.packages = [
    (pkgs.python314.withPackages (
      ps: with ps; [
        pip
        virtualenv
        ipython
        ipykernel
        matplotlib
        pyyaml
        numpy
        pandas
        requests
        httpx
        pydantic-settings
        click
        io
      ]
    ))
  ];
}
