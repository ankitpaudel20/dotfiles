{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      ".envrc"
      ".direnv/"
      "result"
      "result-*"
      "docs/superpowers"
    ];

    settings = {
      user.name = "Ankit Paudel";
      user.email = "53380343+ankitpaudel20@users.noreply.github.com";
      alias = {
        lg = "lg1";
        lg1 = "lg1-specific --all";
        lg2 = "lg2-specific --all";
        lg3 = "lg3-specific --all";

        lg1-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";

        lg2-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";

        lg3-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
      };

      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      difftool.prompt = false;
      pager.difftool = true;
      core.excludesfile = "/home/smloy/.config/git/ignore";

      credential."https://github.com" = {
        helper = [
          ""
          "!gh auth git-credential"
        ];
      };
      credential."https://gist.github.com" = {
        helper = [
          ""
          "!gh auth git-credential"
        ];
      };
    };
  };
}
