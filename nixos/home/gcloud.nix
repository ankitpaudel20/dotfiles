{ pkgs, inputs, ... }:
let
  # google-cloud-sdk is pulled from a pinned nixpkgs (see flake.nix) because
  # the current unstable revision ships a broken bundled python 3.14.5.
  pkgsGcloud = import inputs.nixpkgs-gcloud {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home.packages = [
    (pkgsGcloud.google-cloud-sdk.withExtraComponents [
      pkgsGcloud.google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
  ];
}
