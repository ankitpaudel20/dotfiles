# NixOS Cheat Sheet

This is a quick reference guide for managing your NixOS and Home Manager configuration.

## System Management

### 1. Rebuild and Switch (Standard)
The most common command. This builds the new configuration, makes it the default boot option, and switches to it immediately.
```bash
sudo nixos-rebuild switch --flake .#swift-go
```
*(Run this from your `~/dotfiles/nixos` directory)*

### 2. Test Configuration (Dry Run)
Want to check if your config builds without actually changing your system?
```bash
sudo nixos-rebuild dry-activate --flake .#swift-go
```

### 3. Build and Test (No Bootloader Change)
Builds the config and switches to it, but **does not** add it to the boot menu. Useful for testing risky changes; if the system crashes, simply reboot to revert.
```bash
sudo nixos-rebuild test --flake .#swift-go
```

### 4. Update the Bootloader Only
Builds the config and adds it to the boot menu, but does **not** switch to it now. It will be applied on your next reboot.
```bash
sudo nixos-rebuild boot --flake .#swift-go
```

---

## Flake Management

### 1. Update All Inputs
This updates `flake.lock` to pull the latest versions of Nixpkgs, Home Manager, Plasma Manager, etc.
```bash
nix flake update
```
*Note: Run `nixos-rebuild switch` after this to actually apply the updates.*

### 2. Update a Specific Input
Only want to update a specific input (e.g., just home-manager)?
```bash
nix flake lock --update-input home-manager
```

### 3. Check Flake Errors
Quickly validate your `.nix` files for syntax errors or missing attributes.
```bash
nix flake check
```

---

## Package Search & Exploration

### 1. Search for a Package
```bash
nix search nixpkgs <package_name>
```

### 2. Run a Package Temporarily
Want to use a tool once without installing it? Use `nix run`.
```bash
nix run nixpkgs#htop
```

### 3. Enter a Shell with Multiple Packages
Need a temporary environment with a few specific tools?
```bash
nix shell nixpkgs#python3 nixpkgs#uv nixpkgs#ffmpeg
```

---

## Cleanup and Maintenance

Over time, rebuilding creates many "generations" (snapshots of your system) which take up disk space.

### 1. List Current System Generations
```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

### 2. Delete Old Generations
Deletes all generations older than 14 days (or however many days you specify).
```bash
sudo nix-profile wipe-history --older-than 14d
# OR
sudo nix-env --delete-generations +14d --profile /nix/var/nix/profiles/system
```

### 3. Clean the Nix Store (Garbage Collection)
After deleting generations, you need to actually free up the space from the Nix store.
```bash
sudo nix-store --gc
```

### 4. Optimize Store
Hardlinks identical files in the Nix store to save space.
```bash
nix-store --optimise
```

---

## Modifying Files

Because your files are managed by flakes and tracked by Git:
1. **New Files:** If you create a new `.nix` file, **you must `git add` it** before Nix can see it. If it's not tracked by git, `nix flake check` or `nixos-rebuild` will complain it doesn't exist.
2. **Git Status:** You don't have to commit before rebuilding, but changes must be at least staged (`git add`) or tracked.