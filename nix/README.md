# Home Manager config — operator reference

Standalone Home Manager flake for managing user-level packages and dotfiles on Arch Linux.
System packages stay on pacman/AUR; KDE/Plasma is out of scope.

## Layout

```
~/dotfiles/nix/
├── flake.nix                       # exposes smloy@smloyarch + generic{,-aarch64}
├── flake.lock
├── .envrc                          # `use flake` — auto-loads dev tools when cd here
├── hosts/
│   ├── smloyarch/                  # this machine (Arch)
│   │   └── default.nix             # imports home/common + home/common/arch-overrides.nix
│   └── generic/                    # any fresh non-NixOS Linux box (VPS, container)
│       └── default.nix             # reads $USER/$HOME at activation; imports home/common/core only
└── home/
    └── common/                     # shared HM modules — also imported by ../../nixos
        ├── default.nix             # imports ./core + ./linux-desktop.nix
        ├── core/                   # portable, headless-safe; what `generic` gets
        │   ├── default.nix
        │   ├── shell.nix           # zsh, starship, direnv (portable bits only)
        │   ├── git.nix             # programs.git
        │   ├── tools.nix           # bat, eza, fzf, btop, tmux, jq, rg, fastfetch, croc, dive, aria2, ngrok, …
        │   ├── neovim.nix          # binary only — your ~/.config/nvim is untouched
        │   ├── kube.nix            # kubectl, helm, helm-ls, gh, k9s, krew, argocd
        │   └── devtools.nix        # uv, go, rustup, cmake
        ├── linux-desktop.nix       # foot, xclip, wl-clipboard, wtype, ueberzugpp — Wayland/X11 only
        └── arch-overrides.nix      # SSL_CERT_FILE, SUDO_EDITOR, /opt/google-cloud-cli, generate_python_index_url
                                    #   — imported ONLY by hosts/smloyarch
```

The sibling `~/dotfiles/nixos/` flake imports `nix/home/common` for its NixOS host
(`swift-go`) and layers NixOS-only modules (KDE/Plasma, Zed/VS Code, gcloud, GUI
extras) on top. Swift-go gets `core/` + `linux-desktop.nix`; it does **not** get
`arch-overrides.nix`.

## Generic profile (any non-NixOS Linux box)

For a fresh VPS, container, or new dev machine where you don't want to write a
per-host module first, use the `generic` profile. It reads `$USER` and `$HOME`
at activation, so one command works for any user.

```bash
# 1. Install Determinate Nix (skip if you already have Nix)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. Activate the generic profile
nix run home-manager/master -- switch \
  --flake github:ankitpaudel/dotfiles?dir=nix#generic \
  --impure -b pre-hm
```

- `--impure` is **required** — `hosts/generic/default.nix` reads `$USER`/`$HOME`
  via `builtins.getEnv`. Without it you'll see "USER is empty …".
- Use `generic-aarch64` instead of `generic` on ARM hosts.
- `-b pre-hm` renames pre-existing `~/.zshrc`/`~/.gitconfig`/… out of the way on
  the first activation; safe no-op on repeat runs.

The generic profile gets only `home/common/core/` — no clipboards, no foot
terminal, no Arch-specific paths. Add host-specific overrides via
`~/.zshenv.local` (which `core/shell.nix` sources automatically) rather than
editing the flake per box.

## First-time activation (bootstrap)

Run from `~/dotfiles/nix` (or wherever the flake lives, including via the symlink to `~/nix-config`).

```bash
nix run home-manager/master -- switch --flake .#smloy@smloyarch
```

The matching `arch_normal_install_config/user_configuration.json` deliberately doesn't install pacman zsh or any HM-managed dotfile owner, so there's nothing in `~/` for HM to conflict with on a fresh boot. If you're activating onto a machine that *does* already have a real `~/.zshrc` / `~/.gitconfig` / etc., re-run with `-b pre-hm` to rename them out of the way:

```bash
nix run home-manager/master -- switch --flake .#smloy@smloyarch -b pre-hm
```

After this first run, `home-manager` is on your `$PATH` (via the flake's devShell + direnv) and you don't need `nix run ...` again.

## Daily commands

All run from `~/dotfiles/nix` (devShell auto-activates via direnv):

```bash
home-manager switch --flake .#smloy@smloyarch    # apply changes after editing modules
home-manager generations                          # list past activations
home-manager rollback                             # revert to previous generation
nix flake update                                  # bump nixpkgs + home-manager pins
nix fmt                                           # format all .nix files
nix develop                                       # explicitly enter the dev shell
```

## Verification (after first activation, before pacman cleanup)

Open a fresh shell (`exec zsh`), then check that each binary resolves to `/nix/store/...`, not `/usr/bin/...`:

```bash
which git zsh starship direnv bat eza fzf btop tmux nvim jq rg kubectl helm gh go rustup ngrok aria2 dive croc fastfetch
git lg -n 3      # your gitconfig aliases still work
ll               # eza alias still works
```

If anything resolves to `/usr/bin/`, HM's bin dir isn't first on `$PATH` for that shell. Fix before continuing to the cleanup steps.

## Cleanup after first successful activation

**Order matters.** Activate first, verify, *then* remove duplicates.

### 1. Remove duplicates from `nix profile`

```bash
nix profile remove direnv nix-direnv nixfmt-rfc-style go rustup ngrok
```

Kept on purpose: `nil`, `bfg-repo-cleaner`, `devbox` (out of scope for this flake).

### 2. Remove duplicates from pacman (CLI tools)

```bash
sudo pacman -Rns bat eza fzf btop git-lfs github-cli helm helm-ls-bin jq ripgrep tmux fastfetch croc dive aria2
```

Open a fresh shell, verify everything still works.

### 3. Remove zsh plugins from pacman (HM provides them)

```bash
sudo pacman -Rns zsh-autosuggestions zsh-syntax-highlighting
```

Open another fresh shell, verify autosuggestions + syntax highlighting still appear.

### Kept on pacman intentionally

- `git`, `neovim` — HM also installs them; HM's bin dir wins on `$PATH`. Keeping pacman copies as a safety net for any boot-time/system caller expecting `/usr/bin/git`. Remove later if you want.
- Everything GUI: firefox, brave, discord, kitty/foot/alacritty, zed, dbeaver, gimp, etc.
- KDE/Plasma — entirely out of scope.
- Anything FHS or with weird GPU/driver coupling.

## Adding a new host (future you)

1. `mkdir -p hosts/<newhost>`
2. Copy `hosts/smloyarch/default.nix` to `hosts/<newhost>/default.nix`, change `home.username` / `home.homeDirectory` if different.
3. Add a new entry in `flake.nix`:

   ```nix
   homeConfigurations."<user>@<newhost>" =
     home-manager.lib.homeManagerConfiguration {
       inherit pkgs;
       modules = [ ./hosts/<newhost> ];
     };
   ```

4. On the new machine: `nix run home-manager/master -- switch --flake .#<user>@<newhost> -b pre-hm`

The `home/common/*.nix` modules are shared across hosts. Anything host-specific lives in `hosts/<host>/default.nix` only.

## Rollback / safety

- `home-manager rollback` reverts the most recent activation.
- `home-manager generations` lists every past activation with timestamps; activate any older one with `<gen-path>/activate`.
- Nothing in `/nix/store` is ever mutated — old generations stay until you GC.
- Garbage-collect old generations: `nix-collect-garbage --delete-older-than 30d`.

## Out of scope (never put here)

- Plasma desktop config, KWin scripts, plasmoid settings
- Zed `settings.json` (custom JSON, may contain secrets)
- Anything FHS-dependent or needing kernel/GPU driver alignment
- System services (NetworkManager, bluez, etc.)
- Bootloader, kernel, initramfs

These stay managed by their native tooling (pacman, KDE System Settings, etc.).
