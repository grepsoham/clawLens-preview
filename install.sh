#!/usr/bin/env bash
#
# ClawLens Preview — installer
#
# Downloads the latest preview tarball from GitHub Releases, verifies its
# checksum, extracts to ~/.clawlens-<version>/, updates the ~/.clawlens
# symlink, and registers the plugin in ~/.openclaw/openclaw.json. Restarts
# the gateway and verifies the plugin loaded.
#
# Aborts on first error. On partial install failure, prints explicit
# rollback instructions.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh | bash

set -euo pipefail

readonly REPO="grepsoham/clawLens-preview"
readonly OPENCLAW_CFG="$HOME/.openclaw/openclaw.json"
readonly INSTALL_BASE="$HOME/.clawlens"

C_RED=$'\033[0;31m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[0;33m'
C_RESET=$'\033[0m'

abort() { echo "${C_RED}✗${C_RESET} $*" >&2; exit 1; }
info()  { echo "${C_GREEN}→${C_RESET} $*"; }
warn()  { echo "${C_YELLOW}⚠${C_RESET} $*" >&2; }

# ── Platform detection ──────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) abort "Unsupported OS: $(uname -s). Preview supports macOS and Linux." ;;
esac

# ── SHA verifier ────────────────────────────────────────────────────────────
if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD=(sha256sum -c)
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD=(shasum -a 256 -c)
else
  abort "Need sha256sum or shasum. Install one and re-run."
fi

# ── URL opener (optional) ───────────────────────────────────────────────────
if command -v open >/dev/null 2>&1; then
  OPEN_URL="open"
elif command -v xdg-open >/dev/null 2>&1; then
  OPEN_URL="xdg-open"
else
  OPEN_URL=""
fi

# ── Gateway service control ─────────────────────────────────────────────────
case "$PLATFORM" in
  macos)
    GATEWAY_LABEL="ai.openclaw.gateway"
    gateway_running() { launchctl print "gui/$(id -u)/${GATEWAY_LABEL}" >/dev/null 2>&1; }
    gateway_restart() { launchctl kickstart -k "gui/$(id -u)/${GATEWAY_LABEL}"; }
    ;;
  linux)
    GATEWAY_LABEL="openclaw-gateway"
    gateway_running() { systemctl --user is-active --quiet "${GATEWAY_LABEL}"; }
    gateway_restart() { systemctl --user restart "${GATEWAY_LABEL}"; }
    ;;
esac

echo
echo "ClawLens Preview — Installer"
echo "============================"
echo

# ── Preflight ───────────────────────────────────────────────────────────────
info "Preflight checks..."

for cmd in node npm curl tar jq; do
  command -v "$cmd" >/dev/null 2>&1 || \
    abort "Missing required command: $cmd. Install it (brew install $cmd / apt-get install $cmd) and re-run."
done

node_major=$(node --version | sed -e 's/^v//' -e 's/\..*//')
if ! [[ "$node_major" =~ ^[0-9]+$ ]] || [[ "$node_major" -lt 22 ]]; then
  abort "Node 22+ required (got $(node --version))"
fi

[[ -f "$OPENCLAW_CFG" ]] || \
  abort "$OPENCLAW_CFG not found. Is OpenClaw installed and started at least once?"

jq empty "$OPENCLAW_CFG" 2>/dev/null || \
  abort "$OPENCLAW_CFG contains JSON5 features (comments, trailing commas) that this installer cannot safely edit with jq. Convert to strict JSON manually or reach out for help, then re-run."

# Bonjour preempt — abort with the exact disable command (option (c) of plan)
bonjour_state=$(jq -r '.plugins.entries.bonjour.enabled // "absent"' "$OPENCLAW_CFG")
if [[ "$bonjour_state" != "false" ]]; then
  cat >&2 <<EOF
${C_RED}✗${C_RESET} OpenClaw 2026.4.x has a known bonjour crashloop bug (mDNS announce throws "CIAO ANNOUNCEMENT CANCELLED", putting the gateway into a ~22s restart loop). To proceed safely, disable bonjour first:

  jq '.plugins.entries.bonjour = {enabled: false}' "$OPENCLAW_CFG" > /tmp/openclaw.json.new \\
    && mv /tmp/openclaw.json.new "$OPENCLAW_CFG" \\
    && chmod 600 "$OPENCLAW_CFG" \\
    && launchctl kickstart -k gui/\$(id -u)/${GATEWAY_LABEL}

Then re-run this installer.
EOF
  exit 1
fi

gateway_running || \
  abort "OpenClaw gateway is not running. Start it (e.g., 'brew services start openclaw' or 'systemctl --user start ${GATEWAY_LABEL}') and re-run."

curl -fsS --max-time 5 http://localhost:18789/health >/dev/null || \
  abort "Gateway is up but http://localhost:18789/health is not responding. Check ~/.openclaw/logs/gateway.err.log."

info "Preflight passed."

# ── Fetch latest release ────────────────────────────────────────────────────
info "Fetching latest release tag..."
LATEST_TAG=$(curl -fsS "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tag_name)
[[ -n "$LATEST_TAG" && "$LATEST_TAG" != "null" ]] || \
  abort "Could not fetch latest release from $REPO. Check your network and that a release has been published."

VERSION="${LATEST_TAG#v}"
INSTALL_DIR="${HOME}/.clawlens-${VERSION}"
TARBALL_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/clawlens-${VERSION}.tgz"
CHECKSUM_URL="${TARBALL_URL}.sha256"

info "Latest release: $LATEST_TAG"

# ── Pre-existing install conflict ───────────────────────────────────────────
if [[ -e "$INSTALL_BASE" && ! -L "$INSTALL_BASE" ]]; then
  abort "$INSTALL_BASE exists and is not a symlink. Move or remove it manually, then re-run."
fi

# ── Download ────────────────────────────────────────────────────────────────
info "Downloading tarball + checksum..."
TARBALL="/tmp/clawlens-${VERSION}.tgz"
CHECKSUM="${TARBALL}.sha256"
curl -fsSL "$TARBALL_URL"  -o "$TARBALL"
curl -fsSL "$CHECKSUM_URL" -o "$CHECKSUM"

info "Verifying checksum..."
( cd /tmp && "${SHA_CMD[@]}" "$(basename "$CHECKSUM")" ) >/dev/null 2>&1 || \
  abort "Checksum mismatch — download was corrupted or tampered with. Aborting before any system change."

# ── Extract ─────────────────────────────────────────────────────────────────
info "Extracting to $INSTALL_DIR..."
[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
tar xzf "$TARBALL" --strip-components=1 -C "$INSTALL_DIR"

# ── Runtime deps ────────────────────────────────────────────────────────────
info "Installing runtime dependencies (~30s)..."
( cd "$INSTALL_DIR" && npm install --omit=dev --silent --no-audit --no-fund )

# ── Symlink ─────────────────────────────────────────────────────────────────
info "Updating symlink: $INSTALL_BASE → $INSTALL_DIR"
ln -sfn "$INSTALL_DIR" "$INSTALL_BASE"

# ── Backup openclaw.json ────────────────────────────────────────────────────
TS=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP="${OPENCLAW_CFG}.bak.${TS}"
cp "$OPENCLAW_CFG" "$BACKUP"
chmod 600 "$BACKUP"
info "Backed up openclaw.json → $BACKUP"

# ── Register plugin (atomic + idempotent) ───────────────────────────────────
info "Registering plugin with OpenClaw..."
TMP_CFG="/tmp/openclaw.json.new.$$"
# shellcheck disable=SC2064
trap "rm -f '$TMP_CFG'" EXIT INT TERM

jq --arg path "$INSTALL_BASE" '
  .plugins.load.paths = (((.plugins.load.paths // []) + [$path]) | unique)
  | .plugins.entries.clawlens = ((.plugins.entries.clawlens // {}) + {enabled: true})
' "$OPENCLAW_CFG" > "$TMP_CFG"

jq empty "$TMP_CFG" 2>/dev/null || \
  abort "Generated invalid JSON during registration. Your $OPENCLAW_CFG is unchanged. Backup at $BACKUP."

mv "$TMP_CFG" "$OPENCLAW_CFG"
chmod 600 "$OPENCLAW_CFG"  # jq | mv resets perms — restore them

# ── Restart + wait for ready ────────────────────────────────────────────────
info "Restarting gateway..."
gateway_restart

info "Waiting for gateway to come up (up to 30s)..."
ready=0
for _ in $(seq 1 30); do
  if curl -fsS --max-time 2 http://localhost:18789/plugins/clawlens/api/health >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [[ $ready -ne 1 ]]; then
  warn "Gateway did not become ready in 30s. Last 30 lines of error log:"
  tail -30 "$HOME/.openclaw/logs/gateway.err.log" >&2 2>/dev/null || true
  echo >&2
  warn "To roll back manually:"
  echo "  cp \"$BACKUP\" \"$OPENCLAW_CFG\" && chmod 600 \"$OPENCLAW_CFG\"" >&2
  case "$PLATFORM" in
    macos) echo "  launchctl kickstart -k gui/\$(id -u)/${GATEWAY_LABEL}" >&2 ;;
    linux) echo "  systemctl --user restart ${GATEWAY_LABEL}" >&2 ;;
  esac
  echo >&2
  warn "Or run: curl -fsSL https://raw.githubusercontent.com/${REPO}/main/uninstall.sh | bash"
  exit 1
fi

# ── Success ─────────────────────────────────────────────────────────────────
echo
echo "${C_GREEN}✓ ClawLens v${VERSION} is running.${C_RESET}"
echo
echo "  Dashboard:    http://localhost:18789/plugins/clawlens/"
echo "  Audit log:    ${HOME}/.openclaw/clawlens/audit.jsonl"
echo "  Install dir:  $INSTALL_DIR  (symlinked from $INSTALL_BASE)"
echo "  Backup:       $BACKUP"
echo
echo "  Uninstall:    curl -fsSL https://raw.githubusercontent.com/${REPO}/main/uninstall.sh | bash"
echo

trap - EXIT INT TERM

if [[ -n "$OPEN_URL" ]]; then
  $OPEN_URL "http://localhost:18789/plugins/clawlens/" >/dev/null 2>&1 || true
fi
