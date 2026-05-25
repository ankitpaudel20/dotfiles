{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "nvim-nightfox"
      "catppuccin-icons"
      "html"
      "toml"
      "dockerfile"
      "csv"
      "rainbow-csv"
      "typst"
      "helm"
      "env"
    ];
    userSettings = {
      soft_wrap = "editor_width";
      diff_view_style = "split";
      zoomed_padding = false;
      cli_default_open_behavior = "existing_window";
      project_panel = {
        dock = "left";
      };
      outline_panel = {
        dock = "left";
      };
      collaboration_panel = {
        dock = "left";
      };
      git_panel = {
        dock = "left";
      };
      agent_servers = {
        claude-acp = {
          type = "registry";
        };
        cursor = {
          type = "registry";
        };
      };
      vim_mode = false;
      autosave = "on_focus_change";
      agent = {
        dock = "right";
        default_profile = "write";
        default_model = {
          enable_thinking = true;
          provider = "google";
          model = "gemini-3.1-pro-preview";
        };
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      icon_theme = {
        mode = "dark";
        light = "Catppuccin Frappé";
        dark = "Catppuccin Frappé";
      };
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "dark";
        light = "Dayfox - blurred";
        dark = "Carbonfox - blurred";
      };
      languages = {
        Python = {
          language_servers = [
            "ty"
            "ruff"
          ];
        };
        Nix = {
          language_servers = [
            "nil"
          ];
        };
      };
      file_types = {
        Helm = [
          "**/templates/**/*.tpl"
          "**/templates/**/*.yaml"
          "**/templates/**/*.yml"
          "**/helmfile.d/**/*.yaml"
          "**/helmfile.d/**/*.yml"
          "**/values*.yaml"
        ];
      };
      sticky_scroll = {
        enabled = true;
      };
      format_on_save = "on";
      load_direnv = "direct";
    };
  };
}
