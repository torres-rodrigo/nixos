# Basic System Integration Plan

This plan is a working document for growing the current minimal NixOS
configuration into a usable desktop system. Priorities may change as the system
is tested, and sections may be reordered when a later dependency becomes more
important.

Each section should stay small, easy to review, and easy to revert. When a
section is completed, update its status to `Completed` and add a brief note
describing what was handled.

## Plan Rules

Status: In progress

- Keep each change minimal and independently reversible.
- Prefer explicit imports; do not add `default.nix` directory aggregators.
- Keep `flake.nix` small and delegate outputs to files under `flake/`.
- Use `nixos-rebuild --flake .#nixos` as the activation path.
- Do not require a separate `home-manager switch`.
- Install keeper packages system-wide unless there is a clear user-scoped need.
- Keep dotfiles store-managed by default; use `live/` only for explicit opt-in
  editable links.
- Do not commit plaintext secrets.
- Update `AGENTS.md` whenever project structure or conventions change.

## Current State

Status: Not started

Implemented:

- `flake.nix` declares `nixpkgs`, `home-manager`, and `sops-nix` inputs.
- `flake/nixos-configurations.nix` defines the `nixos` configuration target
  from per-host metadata, including system, hostname, primary user, home path,
  repository path, state version, host config path, and Home Manager profile
  path.
- `flake/apps.nix`, `flake/packages.nix`, and `flake/dev-shells.nix` exist.
- `flake/apps.nix` exposes the local ISO installer as
  `nix run .#install-local`.
- `hosts/nixos/configuration.nix` imports hardware configuration and the users
  module.
- `hosts/nixos/hardware-configuration.nix` exists but is currently empty.
- `disko/disko_config.nix` defines the parameterized single-disk encrypted
  Btrfs layout used by the local installer.
- `scripts/install-local.sh` implements the local ISO install workflow with
  prompt validation, exact disk confirmation, Disko execution, generated
  hardware configuration, and `nixos-install`.
- `modules/nixos/audio.nix` enables a full low-latency PipeWire, PulseAudio
  compatibility, and JACK audio stack.
- `modules/nixos/app-policy.nix` disables Flatpak and documents the policy
  against Snap and AppImage runtime layers.
- `modules/nixos/base.nix` defines shared locale, timezone, and Nix flake CLI
  support.
- `modules/nixos/boot.nix` enables systemd-boot with a zero-second timeout,
  boot editor disabled, and a five-entry generation limit.
- `modules/nixos/dns.nix` enables systemd-resolved with NetworkManager
  integration and fallback DNS resolvers.
- `modules/nixos/firewall.nix` enables a default-deny inbound firewall with no
  custom open ports.
- `modules/nixos/fonts.nix` installs system fonts, packages project-owned font
  assets, and sets fontconfig defaults.
- `modules/nixos/greetd.nix` enables greetd automatic login for the initial
  user.
- `modules/nixos/hardware-intel.nix` enables Intel CPU microcode updates.
- `modules/nixos/home-manager.nix` integrates Home Manager through the NixOS
  rebuild flow.
- `modules/nixos/mango.nix` enables the Mango Wayland compositor through
  nixpkgs.
- `modules/nixos/networking.nix` enables NetworkManager with iwd Wi-Fi support
  and Wi-Fi power-save tuning.
- `modules/nixos/nix-maintenance.nix` enables weekly Nix garbage collection and
  store optimisation.
- `modules/nixos/packages.nix` installs initial keeper packages system-wide.
- `modules/nixos/performance.nix` applies developer-focused sysctl tuning and
  enables irqbalance.
- `modules/nixos/plymouth.nix` enables a custom Plymouth `doom` theme for boot
  splash and LUKS unlock prompts.
- `modules/nixos/storage.nix` enables weekly SSD TRIM and `/tmp` cleanup on
  boot.
- `modules/nixos/users.nix` defines the initial normal user.
- `modules/nixos/wayland.nix` enables the reusable Wayland graphics, session,
  XDG desktop, and portal baseline.
- `modules/home-manager/base.nix` sets XDG base directory session variables to
  keep user config, cache, data, and state under standard hidden directories.
- `modules/home-manager/files.nix` links live Mango and zsh configuration files
  from `live/`.
- `modules/home-manager/zen-browser/` defines store-managed Zen Browser
  hardening, preference, extension, and bookmark inputs.
- `overlays/zen-browser.nix` exposes the local Zen Browser package.
- `pkgs/zen-browser.nix` defines the local Zen Browser package skeleton with a
  placeholder tarball hash pending deployment.
- `users/r/home.nix` defines the initial Home Manager profile for user `r`.

Still missing:

- `flake.lock`.
- First local ISO installation workflow validation on target hardware.
- NVIDIA/graphics baseline.
- Active Home Manager program and dotfile declarations.
- Helper applications around the Mango desktop baseline.
- Dotfile management implementation.
- Secrets scaffolding.
- Real Zen Browser tarball hash before deployment.
- Documented validation workflow.

## Phase 1: Make The Existing Host Rebuildable

Status: Not started

- Generate and commit `flake.lock`.
- Confirm `nixosConfigurations.nixos` evaluates and builds.
- Align the host identity with the project convention, defaulting to the
  `nixos` host target.
- Keep generated hardware details isolated in
  `hosts/nixos/hardware-configuration.nix`.

Completion note:

- Pending.

## Priority Foundations

Status: In progress

- Add boot policy with systemd-boot, no GRUB, zero-second timeout, disabled boot
  editor, and a small boot generation limit.
- Add Nix store and generation maintenance.
- Add filesystem and temp maintenance.
- Add developer performance sysctl and IRQ tuning.
- Add an application format policy forbidding Flatpak, Snap, and AppImage
  runtime layers.
- Add NVIDIA/graphics baseline once hardware topology is known.

Completion note:

- Added `modules/nixos/boot.nix` with systemd-boot enabled, boot timeout set to
  zero seconds, boot entry editing disabled, EFI variable writes enabled, and a
  five-entry systemd-boot generation limit. Added
  `modules/nixos/nix-maintenance.nix` with weekly Nix garbage collection and
  scheduled store optimisation. Added `modules/nixos/storage.nix` with weekly
  SSD TRIM, monthly Btrfs scrub of `/`, and `/tmp` cleanup on boot. Full disk
  layout maintenance remains pending until the real filesystem layout is known.
  Added `modules/nixos/performance.nix` with
  developer-focused sysctl tuning and irqbalance enabled. Added
  `modules/nixos/app-policy.nix` to disable Flatpak and document the policy
  against Snap and AppImage runtime layers. Added
  `modules/nixos/hardware-intel.nix` to enable Intel CPU microcode updates.
  Added `modules/nixos/fonts.nix` to install Noto, Caskaydia Cove Nerd Font,
  packaged custom fonts from `assets/fonts/`, and system fontconfig defaults.
  Added `modules/nixos/plymouth.nix` with a packaged custom `doom` Plymouth
  theme for a polished LUKS unlock prompt and boot splash.
  Other priority foundation sections are still pending.

## Phase 2: Add Shared System Base

Status: In progress

- Add `modules/nixos/base.nix`.
- Move shared system defaults into it, such as Nix settings, locale, timezone if
  shared, networking basics, and other host-neutral defaults.
- Import it explicitly from `hosts/nixos/configuration.nix`.
- Keep host-specific settings in `hosts/nixos/configuration.nix`.

Completion note:

- Introduced `modules/nixos/base.nix` and moved shared timezone, default locale,
  and basic Nix flake CLI settings into it. Added `modules/nixos/networking.nix`
  with NetworkManager enabled, iwd configured as the Wi-Fi backend, and granted
  the initial user access to the `networkmanager` group. Added
  `modules/nixos/firewall.nix` with an explicit default-deny inbound firewall
  and no custom open ports. Added a udev rule to disable Wi-Fi power saving on
  wireless interfaces for workstation reliability. Added `modules/nixos/dns.nix`
  with systemd-resolved enabled, NetworkManager DNS integration, opportunistic
  DNS-over-TLS, DNSSEC allow-downgrade, and Cloudflare/Quad9 fallback resolvers.
  Added a low-latency PipeWire audio module with PulseAudio compatibility, JACK
  support, realtime limits, and audio routing/control tools. Other shared base
  defaults are still pending. Added `modules/nixos/wayland.nix` with reusable
  Wayland graphics, XWayland, seatd, XDG desktop, portal, toolkit environment,
  and support-tool baseline.

## Phase 3: Add System Packages

Status: In progress

- Add `modules/nixos/packages.nix`.
- Start with a small keeper set: shell/editor basics, Git, curl or wget,
  archive tools, diagnostics, and Nix helpers.
- Install packages through `environment.systemPackages`.
- Avoid `home.packages` unless a package is intentionally user-scoped.

Completion note:

- Introduced `modules/nixos/packages.nix` and added the requested base CLI,
  filesystem, media, development, and Nix helper packages system-wide. Tool
  configuration and shell integration are still pending.

## Phase 4: Integrate Home Manager

Status: In progress

- Add `modules/nixos/home-manager.nix`.
- Enable Home Manager through the NixOS module system.
- Set `home-manager.useGlobalPkgs = true`.
- Set `home-manager.useUserPackages = true`.
- Add `users/r/home.nix`.
- Add reusable Home Manager modules:
  - `modules/home-manager/base.nix`
  - `modules/home-manager/programs.nix`
  - `modules/home-manager/files.nix`
- Import every file explicitly.

Completion note:

- Wired Home Manager through the NixOS module system, added the initial `r`
  profile, and created reusable Home Manager base/files/programs modules.
  `files.nix` includes the live/store-managed helper pattern and links live
  Mango and zsh configuration files. Added Starship as the first store-managed
  Home Manager program config in its own module, with the package installed
  system-wide. Moved Starship zsh initialization into the live zsh config so
  shell startup remains editable. Added XDG base directory session variables in
  `modules/home-manager/base.nix` to keep config, cache, data, and state under
  standard hidden directories.

## Phase 5: Add Plymouth And Greetd Boot/Login Baseline

Status: In progress

- Use Plymouth for the LUKS unlock prompt.
- Package project-owned Plymouth assets under `assets/plymouth/`.
- Show a centered DOOM ASCII-art logo above the LUKS entry.
- Show a centered phrase below the logo and rotate it every seven seconds while
  the password prompt is visible.
- Keep copied examples under `temp/` out of the active configuration.
- Use greetd as the minimal login/display manager.
- Automatically log in the initial user after the encrypted disk is unlocked.
- Start the user shell for now; replace this with the Mango session command
  after the desktop module exists.
- Keep disko integration deferred until the disk layout is revisited.

Completion note:

- Added permanent `doom` Plymouth theme files under `assets/plymouth/`,
  adapted the password prompt layout so the lock icon is centered below the
  entry field, added a centered DOOM logo and seven-second phrase rotation,
  enabled Plymouth through `modules/nixos/plymouth.nix`, and added greetd
  autologin through `modules/nixos/greetd.nix`. Full validation is deferred
  until this repository is checked on a NixOS system.

## Phase 6: Add Wayland Baseline

Status: In progress

- Add reusable Wayland graphics/session support before Mango.
- Enable hardware graphics, XWayland, seatd, XDG desktop integration, and
  wlroots portals.
- Add common Wayland toolkit environment variables.
- Add Wayland support tools system-wide.
- Keep user home directories XDG-clean by default and avoid creating
  user-facing top-level directories.

Completion note:

- Added `modules/nixos/wayland.nix` with hardware graphics, 32-bit graphics,
  XWayland, seatd, XDG desktop support, wlroots portals, Wayland toolkit
  session variables, explicit `wlr` then `gtk` portal preference, and support
  tools including clipboard persistence/history and Wayland event inspection.
  Added Home Manager XDG base directory session variables. Full validation is
  deferred until this repository is checked on a NixOS system.

## Phase 7: Add Mango Desktop Baseline

Status: In progress

- Add a focused desktop module, `modules/nixos/mango.nix`.
- Use Mango as the intended window manager.
- Use the `mangowc` package and `programs.mangowc` module from nixpkgs.
- Replace the temporary greetd shell autologin command with the Mango session
  command.
- Keep the first Mango config live-editable under `live/mango/config.conf` and
  link it to `~/.config/mango/config.conf` with Home Manager.
- Add only the minimum surrounding desktop services first:
  - Login/session integration.
  - Fonts.
  - A browser.
  - Terminal helpers.
- Avoid pulling in a full desktop environment unless the Mango setup requires a
  specific component.

Completion note:

- Added `modules/nixos/mango.nix` with `programs.mangowc` enabled, replaced
  the temporary greetd shell command with a Mango session wrapper, and linked
  `live/mango/config.conf` into the user's XDG config directory through Home
  Manager. Added WezTerm as the first terminal helper, set it as the default
  terminal through `xdg-terminal-exec`, and linked its live config from
  `live/wezterm/wezterm.lua`. Added LazyGit with an empty live config at
  `live/lazygit/config.yml`. Browser and other helper applications are still
  pending.

## Phase 7A: Add Zen Browser Baseline

Status: In progress

- Use Zen Browser as the intended default graphical browser for the Mango
  desktop baseline.
- Avoid Flatpak, Snap, and AppImage. Prefer a repo-local Nix package from the
  official Zen Linux tarball until Zen is available directly from nixpkgs.
- Keep the Zen Browser package exposed through the flake but do not install it
  system-wide until the real tarball hash is set.
- Manage browser configuration through Home Manager rather than manual profile
  setup.
- Add a focused Home Manager browser module and import it explicitly from
  `modules/home-manager/programs.nix`.
- Store browser inputs in tracked config files so settings are reproducible:
  - hardening preferences based on LibreWolf defaults
  - extension declarations with stable IDs and install sources
  - bookmark declarations
  - Zen and Firefox-family preference values
- Generate Firefox-family policy/profile configuration from those tracked
  files:
  - package-installed `distribution/policies.json` for enterprise policies,
    extension installation, bookmarks, update/search/telemetry policy, and
    other supported controls
  - Home Manager-managed `user.js` for `about:config` values that are not
    reliably covered by policies
- Include the initial required Zen preference:
  `zen.theme.content-element-separation = 0`.
- Set Zen as the default browser for XDG HTTP, HTTPS, and HTML handlers.
- Enable Wayland-friendly browser behavior through environment or profile
  settings where needed.
- Keep hardening usable: do not break normal downloads, login flows, portals,
  extension installation, or expected desktop integration.
- If the implementation adds a new browser config directory, package pattern,
  or architectural convention, update `AGENTS.md` in the same change.

Completion note:

- Added a local Zen Browser package skeleton, explicit overlay wiring, and
  flake package exposure. Added package-installed browser policies for managed
  extensions and public bookmarks, plus a focused Home Manager Zen module for
  profile preferences, XDG browser defaults, and
  `zen.theme.content-element-separation = 0`. System-wide installation is
  intentionally deferred while the package uses a placeholder hash; add the
  official tarball hash before installing or deploying the browser package.

Deployment steps:

1. On a Nix-capable machine with network access, confirm the desired release.
   Current planned URL:
   `https://github.com/zen-browser/desktop/releases/download/1.21.4b/zen.linux-x86_64.tar.xz`
2. Prefetch the tarball hash without writing a lock file:
   `nix store prefetch-file --json https://github.com/zen-browser/desktop/releases/download/1.21.4b/zen.linux-x86_64.tar.xz`
3. Copy the returned SRI hash, shaped like `sha256-...`, into
   `pkgs/zen-browser.nix` in place of `lib.fakeHash`.
4. Build only the package first:
   `nix build --no-write-lock-file .#packages.x86_64-linux.zen-browser`.
5. If the package builds, add `zen-browser` back to
   `environment.systemPackages` in `modules/nixos/packages.nix`.
6. Run `nix flake check` and `nixos-rebuild build --flake .#nixos`.
7. After first login, confirm `zen` launches, `about:policies` shows active
   policies, uBlock Origin is installed, managed bookmarks appear, and
   `about:config` shows `zen.theme.content-element-separation` set to `0`.

## Phase 8: Implement Dotfile Policy

Status: In progress

- Add `live/` for explicitly opted-in editable dotfiles.
- Keep Home Manager store-managed files as the default.
- Use out-of-store symlinks only for files placed under `live/`.
- Document each live link in the Home Manager files module so it is easy to
  reverse.

Completion note:

- Documented the reversible live-editable and store-managed config workflow in
  `docs/configs_workflow.md`. Added the first live configuration link for
  Mango at `live/mango/config.conf` and live zsh startup files under
  `live/zsh/`. Added live WezTerm and LazyGit configs at
  `live/wezterm/wezterm.lua` and `live/lazygit/config.yml`; additional live
  files are still pending.

## Phase 9: Add Secrets Scaffolding

Status: Not started

- Add `modules/nixos/secrets.nix`.
- Wire in `sops-nix` without adding plaintext secrets.
- Add `secrets/` metadata or encrypted files only when an actual secret is
  needed.
- Keep the first pass as scaffolding unless there is a concrete secret to
  manage.

Completion note:

- Pending.

## Phase 10: Add Local Packages And Overlays Only When Needed

Status: In progress

- Add files under `pkgs/` only when there is a real local package to expose.
- Add files under `overlays/` only for package overrides or additions that must
  affect the configured package set.
- Keep `flake/packages.nix` minimal until there is an actual custom package.
- If the nixpkgs `mangowc` package or module needs local changes, revisit
  whether a local package or overlay is needed.

Completion note:

- Added the first local package and overlay for Zen Browser. The package uses
  the official upstream tarball URL with a placeholder hash and is exposed
  through the flake, but normal system installation is deferred until the real
  hash is added.

## Phase 11: Revisit Host Metadata And Local Paths

Status: Completed

- Move `system`, `username`, `hostname`, and `stateVersion` out of the global
  `flake.nix` let bindings once a second host or user is likely.
- Model those values as per-host metadata in `flake/nixos-configurations.nix`
  so each machine can declare its own target system, host name, primary user,
  and state version.
- Replace the hardcoded `repoPath = "/home/r/projects/nixos"` in
  `modules/nixos/home-manager.nix` with a host/user-provided value.
- Keep the initial behavior unchanged for the current `nixos` host when this is
  implemented.

Completion note:

- Moved NixOS host identity out of global `flake.nix` bindings and into a
  per-host record in `flake/nixos-configurations.nix`. The host record now
  supplies the current system, hostname, primary user, user home, repository
  path, state version, NixOS configuration path, and Home Manager profile path.
  Reusable modules consume that metadata for Home Manager live-link plumbing,
  Mango config paths, greetd startup, and the declared user home while
  preserving the existing `nixos` target behavior.

## Phase 12: Validation Workflow

Status: Not started

- Use the existing dev shell tools for formatting and static checks:
  - `nixfmt`
  - `statix`
  - `deadnix`
- Document and use this validation sequence:
  - `nix flake check`
  - `nixos-rebuild build --flake .#nixos`
  - `nixos-rebuild switch --flake .#nixos` only after build success
- Keep validation manual at first; add automation only after the workflow is
  stable.
- If working away from a NixOS system, defer lock generation, flake checks, and
  rebuild checks until NixOS is available.

Completion note:

- Pending.

## Phase 13: Completion Tracking

Status: Not started

- After finishing a section, update this document's status.
- Add a one- or two-sentence completion note explaining what changed.
- If a completed section adds or changes project structure, workflows, or
  architectural conventions, update `AGENTS.md` in the same change.
- Keep incomplete or reprioritized sections in the document so future work can
  continue without rediscovery.

Completion note:

- Pending.
