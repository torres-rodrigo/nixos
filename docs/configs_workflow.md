# Config Workflow

This project supports moving user configuration files between two states:

- Live-editable files for fast iteration.
- Store-managed Home Manager files for stable, reproducible configuration.

New, experimental, or high-churn application configs should usually start in
`live/`. Once a config is stable, move it into Home Manager so it only changes
through `nixos-rebuild switch --flake .#nixos`.

## Two Config States

### Live-editable

Use this state while actively experimenting.

- The source file lives under `live/`.
- Home Manager links the file with `config.lib.file.mkOutOfStoreSymlink`.
- Edits apply immediately because the target in `$HOME` points at the working
  tree file.
- A rebuild is only needed when adding, removing, or changing the symlink
  declaration itself.

### Store-managed

Use this state when the config is stable.

- The config is declared in Home Manager.
- The file is copied into the Nix store during rebuild.
- Changes require `nixos-rebuild switch --flake .#nixos`.
- This is the default target state for configs that no longer need live editing.

## Directory Pattern

Use predictable paths:

- Live source files: `live/<program>/<file>`
- Home Manager file declarations: `modules/home-manager/files.nix`

Examples:

- `live/waybar/config.jsonc`
- `live/mango/config`
- `live/wezterm/wezterm.lua`

Do not put plaintext secrets in `live/`. Secret values must use the future
`sops-nix` workflow instead.

## Adding A New Live Config

1. Create the config under `live/`.
2. Add a `home.file` entry in `modules/home-manager/files.nix`.
3. Link it with the local `live` helper.
4. Run `nixos-rebuild switch --flake .#nixos` once to create the link.
5. Edit the file under `live/` directly while iterating.

Example:

```nix
{ config, repoPath, ... }:

let
  live = path:
    config.lib.file.mkOutOfStoreSymlink "${repoPath}/live/${path}";
in

{
  home.file.".config/example/config.toml".source = live "example/config.toml";
}
```

`repoPath` is passed through `modules/nixos/home-manager.nix` from the selected
host record in `flake/nixos-configurations.nix`. If the repo moves, update that
host's `repoPath` value.

## Promoting Live Config To Home Manager

Promote a config when it is stable and should become reproducible.

1. Copy the known-good live config into a store-managed Home Manager declaration.
2. Replace the `mkOutOfStoreSymlink` entry with one of:
   - `home.file."<target>".text = '' ... '';`
   - `home.file."<target>".source = ../../path/to/store-managed-file;`
3. Run `nixos-rebuild switch --flake .#nixos`.
4. Confirm the application reads the managed file correctly.
5. Remove the old `live/` file only after the managed version works.

Inline example:

```nix
{
  home.file.".config/example/config.toml".text = ''
    setting = "value"
  '';
}
```

Source-file example:

```nix
{
  home.file.".config/example/config.toml".source =
    ../../dotfiles/example/config.toml;
}
```

## Demoting Managed Config Back To Live

Demote a config when it needs another round of active experimentation.

1. Recreate the config under `live/`.
2. Replace the store-managed `home.file` declaration with
   the `live` helper.
3. Run `nixos-rebuild switch --flake .#nixos` once to switch the link target.
4. Edit the file under `live/` directly.

## Rules

- Use live links only for explicitly opted-in files.
- Keep stable configs store-managed by default.
- Never put plaintext secrets in `live/`.
- Prefer one config promotion or demotion per change.
- Do not use `default.nix` directory aggregators.
- Update this document if the project adds helper functions or changes path
  conventions.
