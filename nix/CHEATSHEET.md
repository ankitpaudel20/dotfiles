# Nix / Home Manager — cheatsheet

Quick reference for `~/dotfiles/nix/`. The README has narrative; this is "what command do I run again?"

All commands assume you're inside `~/dotfiles/nix` (the `.envrc` auto-loads the devShell with `home-manager` + `nixfmt` on `$PATH`).

---

## Daily

| Action | Command |
|---|---|
| Apply current config | `home-manager switch --flake .#smloy@smloyarch` |
| Build without applying | `nix build .#homeConfigurations.\"smloy@smloyarch\".activationPackage --no-link` |
| List past generations | `home-manager generations` |
| Roll back one step | `home-manager rollback` |
| Roll back to specific gen | `<gen-path>/activate` (path from `generations` output) |
| Format all `.nix` files | `nix fmt` |
| Update flake inputs | `nix flake update` |
| Update one input only | `nix flake update home-manager` |
| Show locked input versions | `nix flake metadata` |
| Show flake outputs | `nix flake show` |

---

## Editing config

| I want to... | Touch this file |
|---|---|
| Add a CLI package | `home/tools.nix` (HM module) or `home/kube.nix`/`home/languages.nix` (topical) |
| Add a typed program with shell integration | `home/tools.nix` — `programs.<name>.enable = true` |
| Change a zsh alias | `home/shell.nix` — `programs.zsh.shellAliases` |
| Add a zsh function or PATH export | `home/shell.nix` — `programs.zsh.initContent` |
| Change a git option | `home/git.nix` — `programs.git.extraConfig` |
| Add a git alias | `home/git.nix` — `programs.git.aliases` |
| Add a host-specific override | `hosts/smloyarch/default.nix` |
| Add a new module | Create `home/<name>.nix`, then add `./<name>.nix` to `home/default.nix` imports |
| Add an activation hook (sudo/system bridge) | `home.activation.<name>` in any module — see `home/shell.nix` for the `/etc/shells` example |

---

## Adding a package — recipe

1. Search nixpkgs to find the attribute name:

   ```bash
   nix search nixpkgs <name>          # full match
   nix search nixpkgs ^<name>$        # exact
   ```

   Or web: https://search.nixos.org/packages

2. Decide module:
   - Has a `programs.*` HM module → use it (`programs.<name>.enable = true`)
   - Plain CLI tool → `home.packages = with pkgs; [ ... <name> ];`

3. Edit the relevant file. Add the entry.

4. Apply:

   ```bash
   home-manager switch --flake .#smloy@smloyarch
   ```

---

## Searching for HM-specific options

```bash
# Web (most useful)
xdg-open https://home-manager-options.extranix.com/

# CLI — less ergonomic
nix-instantiate --eval -E '(import <home-manager/modules>).<option-path>'
```

---

## Generations & garbage collection

| Action | Command |
|---|---|
| Disk usage of generations | `du -sh /nix/store` |
| List ALL system generations | `nix-env --list-generations --profile /nix/var/nix/profiles/default` |
| Delete generations older than N days | `nix-collect-garbage --delete-older-than 30d` |
| Delete all but current | `nix-collect-garbage -d` |
| Optimise store (dedup) | `nix store optimise` |

⚠️ `nix-collect-garbage -d` deletes EVERY generation except current. You lose rollback history. Use the `--delete-older-than` form unless you really mean it.

---

## Direnv (per-project devshells)

```bash
direnv allow         # whitelist a .envrc in the current dir
direnv deny          # un-whitelist
direnv reload        # re-evaluate after editing .envrc
direnv status        # show what's loaded
```

Inside a project with `.envrc` containing `use flake`: cd in → tools auto-load. cd out → tools auto-unload.

---

## Inspecting

| Action | Command |
|---|---|
| What's on the current activation? | `ls ~/.nix-profile/bin` |
| Where does X resolve? | `which <cmd>` (any `/nix/store/...` or `~/.nix-profile/bin/...` = HM) |
| What does HM render to `~/.zshrc`? | `cat ~/.zshrc` (it's a symlink into `/nix/store`) |
| What's in a built activation pkg without activating? | `nix build .#homeConfigurations.\"smloy@smloyarch\".activationPackage` then `find -L ./result -type f` |

---

## When build fails

| Error includes... | Cause / fix |
|---|---|
| `Path '...' is not tracked by Git` | Flakes only see git-tracked files. `git add nix/<newpath>` (no need to commit). |
| `error: attribute '<name>' missing` | Wrong attribute name. Check https://search.nixos.org/packages or HM options. |
| `error: undefined variable 'pkgs'` | Module function arg is missing `pkgs` — change `{ ... }:` to `{ pkgs, ... }:`. |
| `infinite recursion` | A module references itself or a cycle. Read the trace; usually a `config.x` reference inside `x`. |
| Hangs at "evaluating..." | Probably evaluating a huge attrset. Ctrl-C, narrow scope. |

---

## When activation fails

```bash
home-manager rollback           # back to previous gen
home-manager generations        # find an even-earlier gen if needed
<that-gen-path>/activate        # explicitly activate it
```

Common activation failures:

- **Conflicting file** (HM refuses to overwrite a real file): `home-manager switch ... -b <ext>` to back it up under that extension. Or `mv ~/<file> ~/<file>.bak` first.
- **Activation hook errors** (e.g., sudo prompt): the rest of activation already succeeded; the hook's failure is non-fatal but logged. Re-run `switch` after fixing.
- **Service file collision** (rare): `systemctl --user list-unit-files` and check for orphan units from a previous gen.

---

## Adding a new host (future you)

```bash
mkdir -p ~/dotfiles/nix/hosts/<newhost>
cp ~/dotfiles/nix/hosts/smloyarch/default.nix ~/dotfiles/nix/hosts/<newhost>/default.nix
# edit the new file: change home.username / homeDirectory if different
```

In `flake.nix` add another entry:

```nix
homeConfigurations."<user>@<newhost>" = home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [ ./hosts/<newhost> ];
};
```

On the new machine:

```bash
nix run home-manager/master -- switch --flake .#<user>@<newhost> -b pre-hm
```

The shared `home/*.nix` modules apply automatically. Anything host-specific stays in `hosts/<newhost>/default.nix`.

---

## Login shell (system bridge)

After every fresh OS install or major shell-config rework, **once per host**:

```bash
# If HM zsh isn't already in /etc/shells (the home.activation hook adds it on next switch)
home-manager switch --flake .#smloy@smloyarch    # triggers the hook

# Switch your login shell — usermod is the safe form (skips /etc/shells validation)
sudo usermod -s "$HOME/.nix-profile/bin/zsh" "$USER"

# Verify
getent passwd "$USER"
~/.nix-profile/bin/zsh -l    # test before logging out

# Then log out / log back in
```

If you ever delete pacman zsh **before** doing the above and lose your login: open a terminal with `kitty /bin/bash` (or `konsole -e /bin/bash`) from KRunner, run `sudo usermod -s ...`, log out, log back in.

---

## Removing a `nix profile` install

```bash
nix profile list                        # find the index/name
nix profile remove <name>
nix profile remove direnv go rustup     # multiple at once
```

Once HM manages a tool, remove it from `nix profile` to avoid dual installs.

---

## Pacman ↔ Nix overlap

After HM provides a tool, the pacman copy is on disk but inert (HM wins on `$PATH` in fresh shells). To fully remove:

```bash
sudo pacman -Rns <pkg>
```

**Never remove pacman zsh, git, or neovim without first** ensuring you have working alternatives (`/etc/passwd` shell for zsh; PATH-resolved binary for git/nvim).

---

## Useful one-offs

```bash
# What's in nixpkgs? (interactive search)
nix-env -qaP <name>

# Run a tool once without installing it
nix run nixpkgs#<name>
nix shell nixpkgs#<name>           # drop into a shell with it on PATH

# Show closure (what a package depends on)
nix-store --query --references $(which <cmd>)
nix path-info -rsh $(which <cmd>)

# Why is X in my closure?
nix-store --query --referrers $(which <cmd>)
```

---

## When stuck

1. Read the actual error line (Nix errors are noisy but the meaningful line is usually 4–6 lines from the bottom).
2. `home-manager rollback` — you can always go back.
3. Your last-known-good config is in git history (`git log nix/`).
4. Pre-HM dotfiles backup (`~/.zshrc.pre-hm`, `~/.gitconfig.pre-hm`) — keep until you're confident.
