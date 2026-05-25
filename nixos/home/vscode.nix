{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default.userSettings = {
      "window.commandCenter" = true;
      "git.blame.editorDecoration.enabled" = true;
      "files.autoSave" = "onFocusChange";
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = false;
      "claudeCode.useCtrlEnterToSend" = true;
      "claudeCode.preferredLocation" = "panel";

      "[python]" = {
        "editor.defaultFormatter" = "charliermarsh.ruff";
        "editor.codeActionsOnSave" = {
          "source.fixAll.ruff" = "explicit";
          "source.organizeImports.ruff" = "explicit";
        };
        "analysis.typeCheckingMode" = "standard";
      };

      "ruff.unsafeFixes" = false;
      "git.autofetch" = true;
      "githubPullRequests.pullBranch" = "never";
      "ruff.codeAction.fixViolation" = {
        "enable" = false;
      };
      "workbench.sideBar.location" = "right";
    };
  };
}
