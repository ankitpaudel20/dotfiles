{ ... }:
{
  programs.zsh.sessionVariables = {
    # Arch/Debian-style cert bundle path; not present on RHEL/Fedora/Alpine/macOS.
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    SUDO_EDITOR   = "/usr/bin/vim";
  };

  programs.zsh.initContent = ''
    # Arch ships google-cloud-cli under /opt; on NixOS the binary is on PATH via gcloud.nix.
    [ -d /opt/google-cloud-cli/bin ] && export PATH="/opt/google-cloud-cli/bin:$PATH"

    generate_python_index_url () {
      : "''${GCP_ARTIFACT_PROJECT:?set GCP_ARTIFACT_PROJECT in ~/.zshenv.local}"
      gcloud auth login
      access_token=$(gcloud auth print-access-token)
      export PYTHON_INDEX_URL="https://oauth2accesstoken:$access_token@us-python.pkg.dev/$GCP_ARTIFACT_PROJECT/packages/simple/"
    }
  '';
}
