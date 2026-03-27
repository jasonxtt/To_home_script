#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Bootstrap installer for to_home_script.

Usage:
  bash bootstrap.sh --repo <owner/repo> [options] [-- <install-home args...>]

Options:
  --repo <owner/repo>     GitHub repository, e.g. tom/to_home_script
  --ref <git-ref>         Git ref/branch/tag (default: main)
  --raw-host <host>       Raw host (default: raw.githubusercontent.com)
  --keep-workdir          Keep temporary working directory for debugging
  -h, --help              Show this help

Examples:
  curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/bootstrap.sh | \
    bash -s -- --repo <owner>/<repo>

  curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/bootstrap.sh | \
    bash -s -- --repo <owner>/<repo> -- --uninstall
EOF
}

log() { printf '[INFO] %s\n' "$*"; }
die() { printf '[ERR] %s\n' "$*" >&2; exit 1; }
require_value() { [[ -n "${2-}" ]] || die "Missing value for $1"; }

pick_downloader() {
  if command -v curl >/dev/null 2>&1; then
    echo "curl"
  elif command -v wget >/dev/null 2>&1; then
    echo "wget"
  else
    die 'Neither curl nor wget is installed'
  fi
}

download_file() {
  local url="$1" out="$2"
  case "$DOWNLOADER" in
    curl) curl -fsSL --retry 3 --connect-timeout 15 -o "$out" "$url" ;;
    wget) wget -q -O "$out" "$url" ;;
    *) die "Unsupported downloader: $DOWNLOADER" ;;
  esac
}

REPO="${TO_HOME_REPO:-}"
REF="${TO_HOME_REF:-main}"
RAW_HOST="${TO_HOME_RAW_HOST:-raw.githubusercontent.com}"
KEEP_WORKDIR="false"
FORWARD_ARGS=()
WORK_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      require_value "$1" "${2-}"
      REPO="$2"
      shift 2
      ;;
    --ref)
      require_value "$1" "${2-}"
      REF="$2"
      shift 2
      ;;
    --raw-host)
      require_value "$1" "${2-}"
      RAW_HOST="$2"
      shift 2
      ;;
    --keep-workdir)
      KEEP_WORKDIR="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      FORWARD_ARGS=("$@")
      break
      ;;
    *)
      die "Unknown option: $1 (use -- to pass args to install-home.sh)"
      ;;
  esac
done

[[ -n "$REPO" ]] || die "Missing --repo <owner/repo>"
[[ "$REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || die "Invalid --repo format: $REPO"
[[ -n "$REF" ]] || die "Invalid --ref"
[[ -n "$RAW_HOST" ]] || die "Invalid --raw-host"

DOWNLOADER="$(pick_downloader)"
WORK_DIR="$(mktemp -d /tmp/to-home-bootstrap.XXXXXX)"

cleanup() {
  if [[ "$KEEP_WORKDIR" != "true" && -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

BASE_URL="https://${RAW_HOST}/${REPO}/${REF}"
log "Downloading scripts from ${BASE_URL}"
download_file "${BASE_URL}/install-home.sh" "${WORK_DIR}/install-home.sh"
download_file "${BASE_URL}/gen-home.sh" "${WORK_DIR}/gen-home.sh"
chmod +x "${WORK_DIR}/install-home.sh" "${WORK_DIR}/gen-home.sh"

cd "$WORK_DIR"
if [[ "$(id -u)" -eq 0 ]]; then
  ./install-home.sh "${FORWARD_ARGS[@]}"
elif command -v sudo >/dev/null 2>&1; then
  sudo ./install-home.sh "${FORWARD_ARGS[@]}"
else
  die 'Please run as root or install sudo'
fi
