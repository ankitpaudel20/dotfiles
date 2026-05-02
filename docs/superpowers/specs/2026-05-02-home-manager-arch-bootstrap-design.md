# Home Manager bootstrap on Arch — design

**Date:** 2026-05-02
**Owner:** smloy (Ankit Paudel)
**Host:** `smloyarch` (x86_64-linux, Arch rolling)
**Nix:** Determinate Nix 3.17.1
**Status:** Approved for implementation

## Goal

Adopt Nix to declaratively manage user-level packages and dotfiles on an Arch Linux daily driver, while leaving system packages, KDE Plasma, and anything FHS/GPU-coupled on pacman/AUR.

## Context

- User is on Arch with KDE Plasma, comfortable with rolling-release tooling.
- Determinate Nix already installed; `~/dotfiles/nix/` contains the `nix flake init` boilerplate (devShell + formatter only).
- Several CLI tools already live in `nix profile`: `bfg-repo-cleaner`, `devbox`, `direnv`, `go`, `ngrok`, `nil`, `nix-direnv`, `nixfmt-rfc-style`, `rustup`.
- Many CLI tools are duplicated between pacman and (future) Nix scope — needs reconciliation.
- A previous abandoned NixOS attempt exists in `nixos/` (currently being deleted in working tree).

## Decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | **Home Manager standalone**, not NixOS or `nix profile`-only | User stays on Arch, wants declarative user packages + dotfile management; HM is the canonical path for this. |
| 2 | **Multi-host scaffolding, single active host** (`smloyarch`) | User wants to add a second host themselves; structure should accommodate from day one. |
| 3 | **Native HM modules** for things HM does well (zsh, git, starship, direnv, fzf, bat, eza, btop, tmux, neovim, jq, ripgrep). **Exclude entirely** anything HM is awkward for (Plasma, Zed JSON, GUI apps). No symlink fallback for now. | Keeps the Nix surface idiomatic; avoids fighting HM where it has good support, avoids fighting Nix where it doesn't. |
| 4 | **Scope: ~20 CLI tools** (Tier B from brainstorming): zsh, git, starship, direnv, fzf, bat, eza, btop, tmux, neovim, helm, helm-ls, kubectl, github-cli (`gh`), jq, ripgrep, fastfetch, croc, dive, aria2, ngrok, go, rustup. | Conservative is too small to feel real; aggressive is too much to verify in one go. B is the meaningful skeleton. |
| 5 | **Flake at `~/dotfiles/nix/` (not repo root)**; user will symlink to `~/nix-config` for invocation convenience. | User preference. |
| 6 | **`nixos-unstable` channel, GitHub inputs** (not flakehub) | User is on rolling Arch; matching unstable Nix avoids "package not in stable yet" friction. GitHub inputs match the bulk of HM ecosystem documentation. |
| 7 | **Neovim: binary only** (`programs.neovim.enable = true; viAlias; vimAlias`). No Nix-managed plugins, no Nix-managed config. `~/.config/nvim/` is read normally. | User explicitly rejected the "Nix manages plugins" rabbit hole. |
| 8 | **Secrets handling deferred** — not needed for current scope. | Nothing in the current scope requires secrets. The leaked GitHub PAT was a separate one-off issue (handled by user, token rotated, value removed from staged Zed config). |

## Architecture

### File layout

```
~/dotfiles/nix/
├── flake.nix
├── flake.lock
├── .envrc                     # `use flake` (already present)
├── README.md                  # operator reference (already written)
├── hosts/
│   └── smloyarch/
│       └── default.nix        # per-host: username, homeDirectory, stateVersion, imports home/
└── home/
    ├── default.nix            # aggregator — imports every module below
    ├── shell.nix              # programs.zsh, programs.starship, programs.direnv
    ├── git.nix                # programs.git
    ├── tools.nix              # bat, eza, fzf, btop, tmux, jq, ripgrep + plain packages
    ├── neovim.nix             # programs.neovim binary-only
    ├── kube.nix               # kubectl, helm, helm-ls, gh
    └── languages.nix          # go, rustup
```

### Conventions

- `hosts/<hostname>/default.nix` is thin: per-host overrides + `imports = [ ../../home ]`.
- `home/default.nix` is an aggregator that imports every module file. Reusable across hosts.
- Each `home/*.nix` module focuses on one concern. Small, readable files.
- Adding a new host = create `hosts/<newhost>/default.nix`, add a `homeConfigurations` entry. Modules unchanged.

### `flake.nix` shape

```nix
{
  description = "smloy home-manager config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations."smloy@smloyarch" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./hosts/smloyarch ];
        };

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [ self.formatter.${system} pkgs.home-manager ];
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
```

Notes:

- `home-manager.inputs.nixpkgs.follows = "nixpkgs"` keeps HM and the user's nixpkgs in sync — no duplicate downloads, no version skew.
- `devShells.default` includes `home-manager` and `nixfmt-rfc-style` so the user gets `home-manager` CLI + `nix fmt` automatically when `cd`-ing into `~/dotfiles/nix/` (via the existing `.envrc` + direnv).
- `config.allowUnfree = true` is required for `ngrok` (and possibly future packages).

### `hosts/smloyarch/default.nix`

```nix
{ ... }:
{
  imports = [ ../../home ];

  home.username = "smloy";
  home.homeDirectory = "/home/smloy";
  home.stateVersion = "25.11";       # pin once, never bump casually
}
```

### `home/default.nix`

```nix
{ ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./tools.nix
    ./neovim.nix
    ./kube.nix
    ./languages.nix
  ];

  programs.home-manager.enable = true;
}
```

## Module specifications

### `home/shell.nix`

**`programs.zsh`** — full migration of `~/.zshrc`:

- `enable = true`
- `history` — replaces all `setopt HIST_*` and `HISTSIZE`/`SAVEHIST`/`HISTFILE` lines:
  - `size = 1_000_000`
  - `save = 1_000_000_000`
  - `share = true`
  - `ignoreAllDups = true`
  - `expireDuplicatesFirst = true`
  - `extended = true`
- `shellAliases`:
  - `svim = "sudo vim"`
  - `tam = "tmux attach -t main || tmux new -s main"`
  - `la = "eza -a --icons=always"`
  - `ll = "eza -al --icons=always"`
  - `lt = "eza -a --tree --level=1 --icons=always"`
- `sessionVariables`:
  - `EDITOR = "nvim"`
  - `VISUAL = "nvim"`
  - `SUDO_EDITOR = "/usr/bin/vim"`
  - `SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket"`
- `autosuggestion.enable = true` — replaces pacman `zsh-autosuggestions`
- `syntaxHighlighting.enable = true` — replaces pacman `zsh-syntax-highlighting`
- `initContent` (verbatim from existing `.zshrc`, things HM doesn't have a typed slot for):
  - `setopt autocd extendedglob`
  - `autoload -Uz compinit; compinit`
  - bindkey lines (ctrl+arrow word jumps, home/end, delete, ctrl+backspace)
  - `generate_python_index_url` function (gcloud auth → PYTHON_INDEX_URL export)
  - `source <(kubectl completion zsh)`
  - `export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"`
  - `export PATH="/opt/google-cloud-cli/bin:$PATH"`
  - gcloud SDK path/completion includes
- **Drop:** manual `source /usr/share/zsh/plugins/...`, manual `source /usr/share/fzf/...`, `eval "$(starship init zsh)"`, `eval "$(direnv hook zsh)"` — all replaced by their respective HM modules.

**`programs.starship`** — `enable = true`. If a `starship.toml` exists, migrate to `programs.starship.settings = {...}`. Defaults otherwise.

**`programs.direnv`**:

- `enable = true`
- `nix-direnv.enable = true`
- `enableZshIntegration = true` (default with zsh enabled, but explicit is clearer)

### `home/git.nix`

**`programs.git`** — full migration of `~/.gitconfig`:

- `enable = true`
- `userName = "Ankit Paudel"`
- `userEmail = "ankitpaudel20000@gmail.com"`
- `aliases` — `lg`, `lg1`, `lg2`, `lg3`, plus the `lg{1,2,3}-specific` long-form definitions (multi-line strings, escape `%` carefully — Nix strings are literal so it's fine).
- `extraConfig`:
  - `init.defaultBranch = "main"`
  - `push.autoSetupRemote = true`
  - `difftool.prompt = false`
  - `pager.difftool = true`
  - `core.excludesfile = "/home/smloy/.config/git/ignore"`
  - `credential."https://github.com".helper` = list `[ "" "!gh auth git-credential" ]` (empty string clears earlier helpers, second sets `gh`-based one). Note: not hardcoding `/usr/bin/gh` — relies on HM's bin dir on `$PATH`.
  - Same for `credential."https://gist.github.com"`.
- `lfs.enable = true` — replaces the `[filter "lfs"]` block, ensures `git-lfs` is on `$PATH`.

### `home/tools.nix`

Native HM modules (each with shell integration auto-enabled):

- `programs.bat.enable = true`
- `programs.eza.enable = true; programs.eza.icons = "always"` — note: HM's eza integration may inject its own `ll`/`la` aliases. Our `shellAliases` in `shell.nix` take precedence (HM merges them in the right order). If conflict, set `programs.eza.enableAliases = false` (or whatever the current attribute is — verify against `home-manager-options` at implementation time).
- `programs.fzf.enable = true; programs.fzf.enableZshIntegration = true`
- `programs.btop.enable = true`
- `programs.tmux.enable = true` (no further opinions yet — user can add later)
- `programs.jq.enable = true`
- `programs.ripgrep.enable = true`

Plain packages (no useful HM module):

```nix
home.packages = with pkgs; [
  fastfetch
  croc
  dive
  aria2
  ngrok
];
```

### `home/neovim.nix`

```nix
programs.neovim = {
  enable = true;
  viAlias = true;
  vimAlias = true;
  defaultEditor = false;            # EDITOR set explicitly in shell.nix
};
```

That is the entire module. No `plugins`, no `extraConfig`, no `extraLuaConfig`. The user's `~/.config/nvim/` is read normally.

### `home/kube.nix`

```nix
home.packages = with pkgs; [
  kubectl
  kubernetes-helm                # this is the actual `helm` binary in nixpkgs
  helm-ls
  gh
];
```

`kubectl completion zsh` and the krew PATH live in `shell.nix:initContent` — no module-level wiring needed.

Note: nixpkgs calls Helm `kubernetes-helm` (the attribute), the binary is still `helm`. Verify at implementation.

### `home/languages.nix`

```nix
home.packages = with pkgs; [
  go
  rustup
];
```

Future improvement (not in scope): consider `fenix` or `oxalica/rust-overlay` for richer Rust toolchain management. For now: pure 1:1 mirror of current `nix profile`.

## Migration plan

### A. `nix profile` reconciliation

| Currently in profile | Action |
|---|---|
| `direnv` | remove — superseded by `programs.direnv` |
| `nix-direnv` | remove — superseded by `programs.direnv.nix-direnv.enable` |
| `nixfmt-rfc-style` | remove — provided by flake's `formatter` output |
| `go` | remove — moved to `home/languages.nix` |
| `rustup` | remove — moved to `home/languages.nix` |
| `ngrok` | remove — moved to `home/tools.nix` |
| `nil` | keep (LSP, used by editors, out of scope for this iteration) |
| `bfg-repo-cleaner` | keep (out of scope, Tier C) |
| `devbox` | keep (out of scope, Tier C) |

Command (run *after* HM activation succeeds and is verified):

```bash
nix profile remove direnv nix-direnv nixfmt-rfc-style go rustup ngrok
```

### B. Pacman cleanup

Two batches, *after* HM activation succeeds:

**Batch 1 — leaf CLI tools** (verify shell still works after):

```bash
sudo pacman -Rns bat eza fzf btop git-lfs github-cli helm helm-ls-bin jq ripgrep tmux fastfetch croc dive aria2
```

**Batch 2 — zsh plugins** (HM-provided versions are sourced from the new `~/.zshrc`, so HM must be active first):

```bash
sudo pacman -Rns zsh-autosuggestions zsh-syntax-highlighting
```

**Kept on pacman intentionally:** `git`, `neovim` (HM versions also installed, but pacman copies remain as a safety net for any boot/system caller expecting `/usr/bin/...`); all GUI apps; KDE/Plasma; FHS/GPU/driver packages.

### C. Existing `nix/flake.nix` template

The current `~/dotfiles/nix/flake.nix` (boilerplate from `nix flake init`) is replaced wholesale by the new flake. The `devShells` and `formatter` outputs are preserved (carried into the new flake), so `cd ~/dotfiles/nix && nix develop` continues to work. The existing `.envrc` (`use flake`) stays as-is.

### D. Order of operations

1. Write all `.nix` files in the repo (no system changes).
2. Stash existing dotfiles via HM's `-b pre-hm` flag.
3. First activation: `nix run home-manager/master -- switch --flake .#smloy@smloyarch -b pre-hm`.
4. Open a fresh shell, run the verification checklist (see README).
5. Remove duplicates from `nix profile` (command above).
6. Remove duplicates from pacman, batch 1.
7. Open a fresh shell, verify again.
8. Remove duplicates from pacman, batch 2.
9. Final shell-restart sanity check.

If anything goes sideways at any step: `home-manager rollback`.

## Activation flow

(Full reference in `~/dotfiles/nix/README.md`; summary here.)

**First-time bootstrap:**

```bash
cd ~/dotfiles/nix
nix run home-manager/master -- switch --flake .#smloy@smloyarch -b pre-hm
```

**Daily commands** (run from `~/dotfiles/nix`, devShell auto-active via direnv):

```bash
home-manager switch --flake .#smloy@smloyarch
home-manager generations
home-manager rollback
nix flake update
nix fmt
```

**Verification** (post-activation, in a fresh shell):

```bash
which git zsh starship direnv bat eza fzf btop tmux nvim jq rg \
      kubectl helm gh go rustup ngrok aria2 dive croc fastfetch
```

Each must resolve to `/nix/store/...`. If any resolves to `/usr/bin/`, `$PATH` ordering is wrong and pacman cleanup is unsafe.

## Out of scope

Explicitly **not** managed by this flake:

- KDE Plasma (entire desktop, kwin, plasmoids, kdeconfig, etc.)
- Zed `settings.json` (custom JSON, evolves often, may contain secrets)
- All GUI apps: firefox, brave, discord, dbeaver, gimp, kitty/foot/alacritty, claude-code, gemini-cli, claude-desktop-appimage
- System services (NetworkManager, bluez, fprintd, fwupd, apparmor, etc.)
- Boot/kernel/firmware (grub, intel-ucode, intel-media-driver, intel-compute-runtime)
- Anything FHS-dependent or GPU/driver-coupled
- Tier-C `nix profile` entries: `bfg-repo-cleaner`, `devbox`, `nil`

## Future considerations (deferred)

- **Secrets:** `sops-nix` or `agenix` if Zed config / API keys / similar move under HM later.
- **Rust toolchain:** `fenix` or `oxalica/rust-overlay` if `rustup`-via-nixpkgs proves limiting.
- **Tier C migration:** if user later wants to migrate more (`devbox`, `bfg-repo-cleaner`, `nil`, GUI apps from `nixpkgs`), it's an additive change to `tools.nix` / new modules.
- **Second host:** documented in README. No design changes needed.
- **Pacman `git` / `neovim` removal:** can be done later once `$PATH` ordering is confirmed reliable across all login paths.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| First activation overwrites a real `~/.zshrc` and aborts | `-b pre-hm` flag renames conflicts to `<file>.pre-hm` |
| HM's bin dir not first on `$PATH`, pacman binaries shadow HM | Verification step: `which` all migrated tools, abort cleanup if any resolve to `/usr/bin/` |
| Pacman zsh-plugins removed before HM activates → broken shell | Removal ordered: HM activates first, then pacman batch 1, *then* zsh plugins |
| Multi-source git config (HM + pacman + dotfiles `.gitconfig`) | HM's generated `~/.gitconfig` overrides others; existing `.gitconfig` is moved aside by `-b pre-hm` |
| Determinate Nix vs. upstream Nix differences | None expected at this scope; flake-based flow is identical |
| Channel updates breaking config | `home-manager rollback` reverses any switch; old generations retained until GC |

## Open questions / explicitly accepted ambiguities

- **eza alias precedence** — HM's eza integration may install its own `ll`/`la` aliases that conflict with the user's `--icons=always` versions. Plan: rely on `shellAliases` overriding, set `programs.eza.enableAliases = false` if needed at implementation. Resolve when writing `tools.nix`.
- **Helm package name** — nixpkgs may expose `kubernetes-helm` or `helm` as the attribute; verify at implementation time.
