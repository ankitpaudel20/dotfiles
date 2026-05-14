{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    helm-ls
    gh
    k9s
    krew
    argocd
  ];
}
