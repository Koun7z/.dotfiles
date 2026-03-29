#!/usr/bin/env bash

if [[ -t 1 ]]; then
  C_RESET='\e[0m'
  C_BOLD='\e[1m'
  C_DIM='\e[2m'
  C_UNDER='\e[4m'

  C_RED='\e[31m'
  C_GRN='\e[32m'
  C_YEL='\e[33m'
  C_BLU='\e[34m'
  C_MAG='\e[35m'
  C_CYN='\e[36m'
  C_WHT='\e[37m'
else
  C_RESET= C_BOLD= C_DIM= C_UNDER= C_RED= C_GRN= C_YEL= C_BLU= C_MAG= C_CYN= C_WHT=
fi
log_info()    { printf "${C_BLU}%s${C_RESET}\n" "$*"; }
log_ok()      { printf "${C_GRN}%s${C_RESET}\n" "$*"; }
log_warn()    { printf "${C_YEL}%s${C_RESET}\n" "$*"; }
log_error()   { printf "${C_RED}%s${C_RESET}\n" "$*"; }


usage() {
BASENAME="apply.sh"
    cat <<EOF
Usage: $BASENAME [OPTIONS]

Stow dotfile packages from the repository.

Options:
  --pkg <pkg...>       Specify one or more package directories to stow.
                       Example:
                         $BASENAME --pkg pkg-zsh pkg-config
                         $BASENAME --pkg "pkg-*"

  -v, --verbose        Enable verbose stow output.
  -n, --no, --simulate Do not make filesystem changes (stow simulate mode).
  -h, --help           Show this help message.

Behavior:
  - If --pkg is provided, only the specified packages are stowed.
  - If --pkg is not provided, the script automatically stows all pkg-*
    directories inside the repository, except those listed in IGNORED_PACKAGES.

Ignored:
  - Packages matching IGNORED_PACKAGES are skipped in automatic mode.
  - Files matched by MANUAL_IGNORE and .gitignore are excluded via --ignore.

Examples:
  Stow all packages automatically:
      $BASENAME

  Explicitly stow two packages:
      $BASENAME --pkg pkg-zsh pkg-config

  Use glob expansion:
      $BASENAME --pkg pkg-*

  Dry run (no changes):
      $BASENAME --simulate

EOF
}


REQUIRED_UTILS=(
    "realpath"
    "git"
    "stow"
    "mktemp"
    "paste"
)

for util in "${REQUIRED_UTILS[@]}"; do
    if ! command -v "$util" >/dev/null 2>&1; then
        log_error "Required utility is not found: '$util'"
        exit 1
    fi
done

STOW_DIR="$(dirname "$(realpath "$0")")"
TARGET_DIR="$HOME"


MANUAL_IGNORE=(
    "README.md"
    "scripts/private"
    "private/*"
    ".p10k.zsh"
    ".p10k-integrated.zsh"
)


IGNORED_PACKAGES=(
    "pkg-private"
    "pkg-test"
    "pkg-p10k" # Not using that any more
)


VERBOSE=""
SIM=""
RESTORE=""
USER_PACKAGES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose)
    VERBOSE="-v"
    shift
    ;;
  -n | --no | --simulate)
    SIM="--simulate"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -D)
    RESTORE="-D"
    shift ;;
  --pkg)
    PARSE_PKGS=true
    shift
    ;;

  --*)
    log_error "Error: Unknown flag: $1" >&2
    exit 1
    ;;

  -*)
    log_error "Unknown option: $1"
    usage
    exit 1
    ;;
  *)
    if [[ "$PARSE_PKGS" = true ]]; then

      if [[ ! -d "$STOW_DIR/$1" ]]; then
        log_error "Error: Package directory not found: '$1'"
        exit 1
      fi

      USER_PACKAGES+=("$1")
      shift
    else
      log_error "Error: Unexpected positional argument: $1"
      exit 1
    fi
    ;;
  esac
done

PACKAGES=()
if [[ ${#USER_PACKAGES[@]} -gt 0 ]]; then
  # User explicitly selected packages
  PACKAGES=("${USER_PACKAGES[@]}")
else
  # Auto-detect all pkg-* directories
  cd "$STOW_DIR" || exit 2

  for pkg in pkg-*; do
    [[ -d "$pkg" ]] || continue

    skip=false
    for ignore in "${IGNORED_PACKAGES[@]}"; do
      if [[ "$pkg" == "$ignore" ]]; then
        skip=true
        break
      fi
    done

    if [[ "$skip" = true ]]; then
      continue
    fi

    PACKAGES+=("$pkg")

  done
fi

GIT_IGNORED=$(git ls-files --others --ignored --exclude-standard --directory)
IGNORE_FILE="$(mktemp)"

printf "%s\n" "$GIT_IGNORED" >>"$IGNORE_FILE"
printf "%s\n" "${MANUAL_IGNORE[@]}" >>"$IGNORE_FILE"
echo ".gitignore" >>"$IGNORE_FILE"

IGNORE_REGEX=$(paste -sd'|' "$IGNORE_FILE")

echo "Ignoring: $IGNORE_REGEX"

echo "Stow from: $STOW_DIR, target: $TARGET_DIR"

cd "$STOW_DIR" || exit 2


STOW_ARGS=()

[[ -n "$VERBOSE" ]] && STOW_ARGS+=("$VERBOSE")
[[ -n "$SIM" ]]     && STOW_ARGS+=("$SIM")
[[ -n "$RESTORE" ]] && STOW_ARGS+=("$RESTORE")

STOW_ARGS+=( --target="$TARGET_DIR" )
STOW_ARGS+=( --ignore="$IGNORE_REGEX" )
STOW_ARGS+=( --dotfiles )


log_info "Stowing packages: ${PACKAGES[*]}"
for pkg in "${PACKAGES[@]}"; do
  log_info "Stowing package: $pkg"
  stow "${STOW_ARGS[@]}" "$pkg"
done

rm "$IGNORE_FILE"
echo "All done, have a nice day :)"
