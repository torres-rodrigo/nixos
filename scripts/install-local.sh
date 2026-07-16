set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-local [--dry-run] [--repo-root PATH]

Run the local NixOS ISO installer for this repository.

Options:
  --dry-run         Generate temporary install files and print commands only.
  --repo-root PATH  Repository root to install from. Defaults to $PWD.
  -h, --help        Show this help.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

prompt_default() {
  local prompt=$1
  local default=$2
  local value

  printf '%s [%s]: ' "$prompt" "$default" >&2
  IFS= read -r value
  if [[ -z "$value" ]]; then
    value=$default
  fi
  printf '%s' "$value"
}

prompt_required() {
  local prompt=$1
  local value

  while true; do
    printf '%s: ' "$prompt" >&2
    IFS= read -r value
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return
    fi
    info "Value is required."
  done
}

prompt_secret() {
  local prompt=$1
  local value

  printf '%s: ' "$prompt" >&2
  IFS= read -rs value
  printf '\n' >&2
  printf '%s' "$value"
}

nix_string() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$\{/\\\$\{}
  printf '"%s"' "$value"
}

validate_username() {
  local value=$1

  [[ "$value" != "root" ]] || die "username must not be root"
  [[ "$value" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]] || die "invalid Linux username: $value"
}

validate_hostname() {
  local value=$1

  [[ ${#value} -le 63 ]] || die "hostname is too long: $value"
  [[ "$value" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || die "invalid hostname: $value"
}

validate_repo_root() {
  local value=$1

  [[ -f "$value/flake.nix" ]] || die "repo root does not contain flake.nix: $value"
  [[ -f "$value/disko/disko_config.nix" ]] || die "repo root does not contain disko/disko_config.nix: $value"
  [[ -f "$value/flake/nixos-configurations.nix" ]] || die "repo root does not contain flake/nixos-configurations.nix: $value"
  [[ "$value" != *[[:space:]]* ]] || die "repo root paths containing whitespace are not supported by this installer"
}

validate_disk() {
  local disk=$1
  local resolved
  local type

  [[ -e "$disk" ]] || die "target disk does not exist: $disk"
  resolved=$(readlink -f -- "$disk")
  [[ -b "$resolved" ]] || die "target is not a block device: $disk"

  type=$(lsblk -dnro TYPE -- "$resolved")
  [[ "$type" == "disk" ]] || die "target is not a whole disk: $disk"

  if lsblk -nrpo MOUNTPOINTS -- "$resolved" | grep -q '[^[:space:]]'; then
    die "target disk or one of its partitions is mounted; unmount it before installing"
  fi

  printf '%s' "$resolved"
}

write_install_files() {
  local work_dir=$1
  local repo_root=$2
  local username=$3
  local hostname=$4
  local disk=$5

  local repo_root_nix
  local username_nix
  local hostname_nix
  local disk_nix
  local user_home_nix

  repo_root_nix=$(nix_string "$repo_root")
  username_nix=$(nix_string "$username")
  hostname_nix=$(nix_string "$hostname")
  disk_nix=$(nix_string "$disk")
  user_home_nix=$(nix_string "/home/$username")

  cat > "$work_dir/install-host.nix" <<'INSTALL_HOST'
{ lib, username, ... }:

let
  rootHash = lib.removeSuffix "\n" (builtins.readFile ./root-password-hash);
  userHash = lib.removeSuffix "\n" (builtins.readFile ./user-password-hash);
in
{
  users.mutableUsers = true;
  users.users.root.hashedPassword = rootHash;
  users.users.${username}.hashedPassword = userHash;
}
INSTALL_HOST

  cat > "$work_dir/install-disko.nix" <<INSTALL_DISKO
import ${repo_root}/disko/disko_config.nix {
  diskDevice = ${disk_nix};
}
INSTALL_DISKO

  cat > "$work_dir/flake.nix" <<TEMP_FLAKE
{
  description = "Temporary local installer wrapper for this NixOS repository";

  inputs = {
    repo.url = "path:${repo_root}";
    nixpkgs.follows = "repo/nixpkgs";
    home-manager.follows = "repo/home-manager";
  };

  outputs = { nixpkgs, home-manager, repo, ... }:
    {
      nixosConfigurations = import (repo.outPath + "/flake/nixos-configurations.nix") {
        inherit nixpkgs home-manager;

        hostOverrides.nixos = {
          hostname = ${hostname_nix};
          username = ${username_nix};
          userHome = ${user_home_nix};
          repoPath = ${repo_root_nix};
        };

        extraModules = [
          ./install-host.nix
        ];
      };
    };
}
TEMP_FLAKE
}

dry_run_commands() {
  local work_dir=$1
  local repo_root=$2

  cat <<COMMANDS
Dry run complete. The installer would run:

  install -m 0600 "$work_dir/luks-passphrase" /run/doom-disko-luks-password
  disko --mode destroy,format,mount "$work_dir/install-disko.nix"
  nixos-generate-config --root /mnt --show-hardware-config > "$repo_root/hosts/nixos/hardware-configuration.nix"
  nixos-install --flake "$work_dir#nixos" --no-root-passwd
COMMANDS
}

main() {
  local dry_run=0
  local repo_root=$PWD

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=1
        shift
        ;;
      --repo-root)
        [[ $# -ge 2 ]] || die "--repo-root requires a path"
        repo_root=$2
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done

  repo_root=$(cd "$repo_root" && pwd -P)
  validate_repo_root "$repo_root"

  if [[ $dry_run -eq 0 && ${EUID:-$(id -u)} -ne 0 ]]; then
    die "run as root from the NixOS ISO, or use --dry-run"
  fi

  local username
  local hostname
  local disk
  local resolved_disk
  local secret
  local secret_repeat
  local volatile_confirm
  local final_confirm
  local work_dir

  username=$(prompt_default "Username" "r")
  validate_username "$username"

  hostname=$(prompt_default "Hostname" "nixos")
  validate_hostname "$hostname"

  disk=$(prompt_required "Target disk path")
  resolved_disk=$(validate_disk "$disk")

  info ""
  info "Selected disk:"
  lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS -- "$resolved_disk"

  if [[ "$disk" != /dev/disk/by-id/* ]]; then
    info ""
    info "Warning: $disk is not a stable /dev/disk/by-id/... path."
    printf 'Type ALLOW to continue with this volatile disk path: ' >&2
    IFS= read -r volatile_confirm
    [[ "$volatile_confirm" == "ALLOW" ]] || die "aborted"
  fi

  secret=$(prompt_secret "Shared LUKS/root/user secret")
  [[ -n "$secret" ]] || die "secret must not be empty"
  secret_repeat=$(prompt_secret "Repeat shared secret")
  [[ "$secret" == "$secret_repeat" ]] || die "secrets do not match"
  secret_repeat=

  info ""
  info "This will permanently erase all data on:"
  info "  $disk"
  info ""
  info "The disk will be repartitioned, formatted, encrypted, and installed as NixOS."
  printf 'To continue, type the exact disk path: ' >&2
  IFS= read -r final_confirm
  [[ "$final_confirm" == "$disk" ]] || die "disk confirmation did not match; aborted"

  work_dir=$(mktemp -d -t nixos-local-install.XXXXXX)
  chmod 0700 "$work_dir"

  cleanup() {
    rm -rf "$work_dir"
  }
  trap cleanup EXIT
  trap 'cleanup; exit 130' INT TERM

  umask 077
  printf '%s\n' "$secret" > "$work_dir/luks-passphrase"
  printf '%s\n' "$secret" | mkpasswd --method=yescrypt --stdin > "$work_dir/root-password-hash"
  printf '%s\n' "$secret" | mkpasswd --method=yescrypt --stdin > "$work_dir/user-password-hash"
  secret=
  chmod 0600 "$work_dir/luks-passphrase" "$work_dir/root-password-hash" "$work_dir/user-password-hash"

  write_install_files "$work_dir" "$repo_root" "$username" "$hostname" "$disk"

  if [[ $dry_run -eq 1 ]]; then
    dry_run_commands "$work_dir" "$repo_root"
    exit 0
  fi

  install -m 0600 "$work_dir/luks-passphrase" /run/doom-disko-luks-password
  disko --mode destroy,format,mount "$work_dir/install-disko.nix"
  nixos-generate-config --root /mnt --show-hardware-config > "$repo_root/hosts/nixos/hardware-configuration.nix"
  nixos-install --flake "$work_dir#nixos" --no-root-passwd

  info ""
  info "Install complete. Reboot, unlock LUKS with the bootstrap secret, then rotate root and user passwords."
}

main "$@"
