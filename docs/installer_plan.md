# Installer Plan

## Purpose

This document specifies the installer for this repository. The installer
collects install-time values, writes only temporary configuration, prepares the
Disko and NixOS install configuration, and installs NixOS from a local NixOS ISO.

The implemented first flow runs directly on the target from the NixOS ISO:

- Boot the target machine into the NixOS ISO.
- Clone or copy this repository onto the live system.
- Run `nix run .#install-local` from the repository root.

The later controller-driven flow should use `nixos-anywhere` from another
machine over SSH. The Disko layout and temporary secret convention are kept
compatible with that future path.

Both flows use one prompted secret as the LUKS passphrase, root password, and
normal user password. This matches the intended initial behavior, but it is a
security tradeoff: compromise or disclosure of that one secret compromises all
three authentication surfaces until the installed passwords are rotated.

## Installation Model

The installer has two phases.

The first phase is an interactive bootstrap step. It runs before any destructive
operation and gathers:

- Username.
- Hostname.
- Target drive, preferably a stable `/dev/disk/by-id/...` path.
- One secret to reuse as the LUKS passphrase, root password, and user password.

The bootstrap step must:

- Validate that the selected disk path exists and is a whole disk.
- Prefer `/dev/disk/by-id/...` paths over volatile names such as `/dev/sda` or
  `/dev/nvme0n1`.
- Display the selected disk, model, size, serial when available, and current
  partition table.
- Require a final destructive confirmation by asking the operator to type the
  exact disk path again.
- Create a temporary working directory with mode `0700`.
- Write the prompted secret only to a temporary LUKS passphrase file.
- Generate root and user password hashes with `mkpasswd` using yescrypt, or the
  current NixOS-supported default when that changes.
- Never write plaintext passwords, password hashes, or generated install
  secrets into committed repo files.
- Remove the temporary working directory on normal exit and on common signals.

The second phase consumes the generated temporary files and performs the local
ISO install flow:

- Copy the temporary LUKS passphrase to `/run/doom-disko-luks-password`.
- Run Disko in `destroy,format,mount` mode.
- Generate `hosts/nixos/hardware-configuration.nix` from `/mnt`.
- Run `nixos-install` through a temporary wrapper flake.

## Inputs Collected By The Installer

The installer should prompt exactly for these values:

```text
Username: <name>
Hostname: <host>
Target disk path: /dev/disk/by-id/<stable-id>
Shared LUKS/root/user secret: <hidden input>
Repeat shared secret: <hidden input>
Type the target disk path to erase it: /dev/disk/by-id/<stable-id>
```

Validation rules:

- Username must be a valid Linux user name, lower-case by default, and must not
  be `root`.
- Hostname must be a valid Linux hostname label.
- Target disk must exist, must not be a partition, and should resolve to a
  block device shown by `lsblk`.
- Target disk should use `/dev/disk/by-id/...`. Allow volatile `/dev/...` paths
  only behind an explicit warning.
- The repeated secret must match the first entry.
- The final disk confirmation must byte-match the selected disk path.

The installer should show this warning before the final confirmation:

```text
This will permanently erase all data on:
  <disk path>

The disk will be repartitioned, formatted, encrypted, and installed as NixOS.
To continue, type the exact disk path.
```

## Generated Install-Time Configuration

Permanent, reusable configuration belongs in this repository. Machine-specific
or secret install fragments belong in a temporary directory created by the
installer.

The temporary directory should have this shape:

```text
$TMPDIR/
  luks-passphrase
  root-password-hash
  user-password-hash
  install-host.nix
  install-disko.nix
  flake.nix
```

File handling rules:

- `$TMPDIR` mode: `0700`.
- `luks-passphrase` mode: `0600`.
- `root-password-hash` mode: `0600`.
- `user-password-hash` mode: `0600`.
- Generated Nix files should not contain plaintext secrets.
- Password hash files should not be copied into the repo.
- The temporary directory should be deleted when the installer exits.

The implementation keeps using the per-host metadata pattern from
`flake/nixos-configurations.nix`. The temporary wrapper flake passes
`hostOverrides` and `extraModules` so install-time values can be layered on top
of the committed `nixos` host without editing committed files.

The wrapper can override:

- `system`
- `hostname`
- `username`
- `userHome`
- `repoPath`
- `stateVersion`
- `configuration`
- `home`

The generated one-shot install module should set only install-time values that
must not be committed, such as:

```nix
{ lib, username, ... }:

{
  users.mutableUsers = true;
  users.users.root.hashedPassword =
    lib.removeSuffix "\n" (builtins.readFile ./root-password-hash);
  users.users.${username}.hashedPassword =
    lib.removeSuffix "\n" (builtins.readFile ./user-password-hash);
}
```

Use hashed password values read from temporary hash files, rather than
plaintext password options. Do not leave `hashedPasswordFile` pointing at a
temporary path in the installed generation; the file is deleted after install
and would break later activations. Keep `users.mutableUsers = true` unless the
project intentionally changes its user management policy later; this allows the
installed root and user passwords to be changed normally after first boot.

## Disko Design

Disko is the declarative partitioning, formatting, and mounting layer for this
install. It should own the disk layout so the filesystem structure is
reproducible and can be mounted again for recovery.

`disko/disko_config.nix` is a parameterized layout that accepts `diskDevice`.
The selected disk is threaded in through the generated `install-disko.nix` file
instead of editing committed configuration.

The intended single-disk layout remains:

- GPT partition table.
- 1G EFI System Partition mounted at `/boot`.
- Restrictive VFAT mount options for `/boot`, including `umask=0077`.
- Remaining disk as a LUKS2 container named `cryptroot`.
- LUKS password read from `/run/doom-disko-luks-password`.
- Btrfs inside LUKS.
- Btrfs subvolumes for `/`, `/home`, `/nix`, `/var`, and `/var/log`.

Layer responsibilities:

- GPT provides a modern partition table with clear partition typing.
- The ESP supports systemd-boot and UEFI boot.
- LUKS encrypts the system data partition.
- Btrfs subvolumes separate operational areas without fixed-size partitions.
- `/var/log` uses `nodatacow` to reduce copy-on-write overhead for logs.

The LUKS passphrase convention is:

```text
/run/doom-disko-luks-password
```

For `nixos-anywhere`, the controller uploads the local temporary secret file to
that remote path with `--disk-encryption-keys`. For local ISO fallback, the
installer creates `/run/doom-disko-luks-password` directly with mode `0600`
before running Disko.

Disk selection rules:

- Use stable disk IDs from `/dev/disk/by-id/` whenever possible.
- Show `lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS`.
- Refuse to proceed if any selected disk partition is mounted, unless the
  operator explicitly unmounts it first.
- Require the operator to type the exact selected disk path before wipe.

Disko execution modes:

- `destroy,format,mount` wipes existing content, creates the declared layout,
  formats it, and mounts it under `/mnt`.
- `mount` mounts an already-created layout, useful for recovery or repair.
- `--dry-run` can inspect the generated scripts without touching disks.

## nixos-anywhere Design

`nixos-anywhere` installs NixOS over SSH from a source/controller machine. The
controller needs Nix with flakes enabled. The target must be reachable over SSH.
For a blank machine, boot the target into the standard NixOS ISO first.

Target ISO preparation:

1. Boot the target from the NixOS ISO.
2. Set a password for the ISO `nixos` user:

   ```console
   passwd
   ```

3. Find the target IP address:

   ```console
   ip addr
   ```

4. From the controller, verify SSH access:

   ```console
   ssh nixos@<target-ip>
   ```

The install command should be shaped like this:

```console
nix run github:nix-community/nixos-anywhere -- \
  --flake .#nixos \
  --target-host nixos@<target-ip> \
  --disk-encryption-keys /run/doom-disko-luks-password <local-temp-secret-file> \
  --generate-hardware-config nixos-generate-config hosts/<host>/hardware-configuration.nix
```

When the generated install profile exists, the flake target may become a
dedicated install output instead of `.#nixos`, but the command shape should stay
the same.

`nixos-anywhere` phases are normally:

- `kexec`
- `disko`
- `install`
- `reboot`

When the target is already booted into a NixOS ISO, `nixos-anywhere` detects the
installer environment and skips `kexec`. This is useful for machines that do not
support `kexec` or do not have enough RAM for it.

Warnings:

- The target disk is completely overwritten.
- The installed system's SSH host key will differ from the ISO or previous
  system host key.
- After install, the controller may need to remove the old known-hosts entry:

  ```console
  ssh-keygen -R <target-ip>
  ```

## Local ISO Flow

The local flow runs directly on the target after booting into the NixOS ISO. It
is the implemented v1 installer path.

Run it from the repository root:

```console
sudo nix run .#install-local
```

For a non-destructive prompt and generated-command check:

```console
nix run .#install-local -- --dry-run
```

The command performs this sequence after final confirmation:

- `install -m 0600 <temp-secret> /run/doom-disko-luks-password`
- `disko --mode destroy,format,mount <temp-install-disko.nix>`
- `nixos-generate-config --root /mnt --show-hardware-config >
  hosts/nixos/hardware-configuration.nix`
- `nixos-install --flake <temp-wrapper-flake>#nixos --no-root-passwd`

The temporary wrapper flake imports this repository's host builder with an
install-only password module. The generated hardware configuration is committed
later as normal machine hardware state.

## Implementation Stages

### Stage 1: Documentation Scaffold

Create `docs/installer_plan.md` with a clear separation between the
controller-over-SSH flow and the local ISO fallback flow.

Definition of done:

- The document exists.
- The primary and fallback install models are visibly separate.

### Stage 2: Installer Interface Design

Document the exact prompts, validation rules, confirmation text, and temporary
directory layout.

Definition of done:

- An implementer knows every input.
- An implementer knows where generated files are stored.
- An implementer knows which files must be deleted on exit.

### Stage 3: Disko Integration

Parameterize the current Disko config with the selected disk. Provide
`/run/doom-disko-luks-password` from the generated local secret file.

Definition of done:

- The selected disk can be threaded into Disko without editing committed files.
- No plaintext secret or generated hash is committed.

Status: Implemented.

### Stage 4: NixOS Config Completion

Add a generated install module for hostname, username, root/user hashed password
files, and hardware configuration path. Keep host metadata explicit and
compatible with `flake/nixos-configurations.nix`.

Definition of done:

- Generated config completes the existing host metadata.
- Passwords are provided through hash files.
- No plaintext secrets are present in committed configuration.

Status: Implemented for the local ISO flow through a temporary wrapper flake,
`hostOverrides`, and `extraModules`.

### Stage 5: Local ISO Flow

Implement the local ISO command as `nix run .#install-local`.

Definition of done:

- The command includes prompt validation, disk confirmation, Disko execution,
  hardware config generation, and `nixos-install`.
- `--dry-run` prints the destructive commands without running them.

Status: Implemented.

### Stage 6: nixos-anywhere Flow

Document and implement target ISO prep, SSH connection testing, generated
hardware config, disk encryption key upload, and the final install command.

Definition of done:

- The install command includes the flake target, target host, disk encryption
  key upload, and hardware config generation.
- The documented phases explain what happens during install.

Status: Future work.

### Stage 7: Post-Install Checks

After first boot, verify:

- LUKS prompt appears and accepts the shared secret.
- Root login works if enabled by the relevant login path.
- User login works.
- Hostname matches the prompted hostname.
- User groups match the configured desktop/workstation expectations.
- Home Manager activation completed through the NixOS rebuild.
- Mango and greetd reach the intended session.
- Btrfs subvolumes are mounted at `/`, `/home`, `/nix`, `/var`, and
  `/var/log`.
- `nixos-rebuild switch --flake .#nixos` succeeds on the installed system.

Definition of done:

- A successful install has objective acceptance criteria.
- Any failed check has a clear next diagnostic command.

## Security Rules

- Do not commit plaintext secrets.
- Do not commit generated password hashes.
- Do not commit generated temporary install modules that contain local secret
  file paths.
- Use a `0700` temporary directory for installer working files.
- Use `0600` permissions for secret and hash files.
- Prefer yescrypt hashes from `mkpasswd`, or the current NixOS-supported
  default if that changes.
- Treat the shared secret as temporary bootstrap material.
- Rotate at least the root and user passwords after first successful boot.
- Consider rotating the LUKS passphrase after first boot if the install
  environment or controller was not fully trusted.
- Never place install secrets under `live/`, `docs/`, `hosts/`, `modules/`,
  `secrets/`, or any other committed repo path.

## Validation And Definition Of Done

The local installer work is complete when:

- `nix run .#install-local` installs the `nixos` host from a NixOS ISO target.
- The selected disk is always confirmed with an exact path re-entry before wipe.
- The Disko config is parameterized and no committed disk path edit is needed.
- LUKS uses `/run/doom-disko-luks-password` during formatting.
- Root and user passwords are set from generated hashes, not plaintext options.
- Temporary files are cleaned up after install attempts.
- First boot reaches the configured Plymouth, greetd, Mango, and Home Manager
  baseline.
- `nixos-rebuild switch --flake .#nixos` succeeds after first boot.

The later `nixos-anywhere` path is complete only when the controller-over-SSH
flow installs the same host with the same Disko layout and LUKS passphrase
upload convention.

## References

- [nixos-anywhere quickstart](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md)
- [nixos-anywhere reference](https://github.com/nix-community/nixos-anywhere/blob/main/docs/reference.md)
- [nixos-anywhere secrets and full disk encryption](https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/secrets.md)
- [nixos-anywhere no operating system install](https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/no-os.md)
- [Disko quickstart](https://github.com/nix-community/disko/blob/master/docs/quickstart.md)
- [Disko disko-install](https://github.com/nix-community/disko/blob/master/docs/disko-install.md)
- [NixOS `users.users.<name>.hashedPasswordFile` option](https://search.nixos.org/options?query=users.users.%3Cname%3E.hashedPasswordFile)
- [NixOS `users.mutableUsers` option](https://search.nixos.org/options?query=users.mutableUsers)
