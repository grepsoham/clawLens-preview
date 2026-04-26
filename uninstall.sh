#!/usr/bin/env bash
#
# ClawLens Preview — uninstaller
#
# Restores the most recent installer-created openclaw.json backup,
# surgically removes any lingering clawlens plugin entries, deletes
# the ~/.clawlens symlink and all ~/.clawlens-* versioned install
# dirs, restarts the gateway, and verifies ClawLens is no longer
# registered.
#
# Audit log at ~/.openclaw/clawlens/audit.jsonl is preserved — rm
# manually if you want it gone.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/uninstall.sh | bash

set -euo pipefail

readonly OPENCLAW_CFG="$HOME/.openclaw/openclaw.json"

C_RED=$'\033[0;31m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[0;33m'
C_RESET=$'\033[0m'

abort() { echo "${C_RED}✗${C_RESET} $*" >&2; exit 1; }
info()  { echo "${C_GREEN}→${C_RESET} $*"; }
warn()  { echo "${C_YELLOW}⚠${C_RESET} $*" >&2; }

# ── Platform detection (mirrors install.sh) ─────────────────────────────────
case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  Linux)  PLATFORM=linux ;;
  *) abort "Unsupported OS: $(uname -s)" ;;
esac

case "$PLATFORM" in
  macos)
    GATEWAY_LABEL="ai.openclaw.gateway"
    gateway_restart() { launchctl kickstart -k "gui/$(id -u)/${GATEWAY_LABEL}"; }
    ;;
  linux)
    GATEWAY_LABEL="openclaw-gateway"
    gateway_restart() { systemctl --user restart "${GATEWAY_LABEL}"; }
    ;;
esac

echo
echo "ClawLens Preview — Uninstaller"
echo "=============================="
echo

[[ -f "$OPENCLAW_CFG" ]] || abort "$OPENCLAW_CFG not found — nothing to uninstall from."

command -v jq >/dev/null 2>&1 || \
  abort "Missing jq. Install it (brew install jq / apt-get install jq) and re-run."

# ── Find most recent installer-created backup ───────────────────────────────
# install.sh creates backups named: openclaw.json.bak.<YYYYMMDDTHHMMSSZ>
# We match that exact format to avoid restoring unrelated backup files
# (e.g., from other tools or manual snapshots with custom suffixes).
LATEST_BACKUP=$(ls -t "$HOME"/.openclaw/openclaw.json.bak.* 2>/dev/null | grep -E 'bak\.[0-9]{8}T[0-9]{6}Z$' | head -n 1 || true)

if [[ -n "$LATEST_BACKUP" ]]; then
  info "Restoring openclaw.json from $LATEST_BACKUP"
  cp "$LATEST_BACKUP" "$OPENCLAW_CFG"
  chmod 600 "$OPENCLAW_CFG"
else
  warn "No installer-created backup found — falling back to surgical removal only."
fi

# ── Surgical removal (idempotent — handles multi-version installs + gaps) ──
info "Removing any remaining clawlens entries from openclaw.json..."
TMP_CFG="/tmp/openclaw.json.uninstall.$$"
# shellcheck disable=SC2064
trap "rm -f '$TMP_CFG'" EXIT INT TERM

jq empty "$OPENCLAW_CFG" 2>/dev/null || \
  abort "$OPENCLAW_CFG is not valid JSON. Cannot safely surgically remove clawlens entries."

jq --arg path "$HOME/.clawlens" '
  .plugins.load.paths = ((.plugins.load.paths // []) | map(select(. != $path)))
  | del(.plugins.entries.clawlens)
' "$OPENCLAW_CFG" > "$TMP_CFG"

if jq empty "$TMP_CFG" 2>/dev/null; then
  mv "$TMP_CFG" "$OPENCLAW_CFG"
  chmod 600 "$OPENCLAW_CFG"
else
  rm -f "$TMP_CFG"
  abort "Surgical removal produced invalid JSON. $OPENCLAW_CFG left as-is."
fi

# ── Remove install dirs + symlink ───────────────────────────────────────────
info "Removing ~/.clawlens symlink and any ~/.clawlens-* dirs..."
[[ -L "$HOME/.clawlens" ]] && rm -f "$HOME/.clawlens"
shopt -s nullglob
for d in "$HOME/.clawlens-"*; do
  [[ -d "$d" ]] && rm -rf "$d"
done
shopt -u nullglob

# ── Restart + verify ────────────────────────────────────────────────────────
info "Restarting gateway..."
gateway_restart

info "Waiting for gateway (up to 30s)..."
ready=0
for _ in $(seq 1 30); do
  if curl -fsS --max-time 2 http://localhost:18789/health >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [[ $ready -ne 1 ]]; then
  warn "Gateway didn't come up in 30s. Check ~/.openclaw/logs/gateway.err.log."
  exit 1
fi

clawlens_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 http://localhost:18789/plugins/clawlens/ 2>/dev/null || echo "?")
if [[ "$clawlens_status" != "404" ]]; then
  warn "Expected /plugins/clawlens/ → 404 after uninstall, got $clawlens_status."
  warn "ClawLens may still be registered. Inspect $OPENCLAW_CFG manually."
  exit 1
fi

trap - EXIT INT TERM

echo
echo "${C_GREEN}✓ ClawLens removed.${C_RESET}"
echo
echo "  openclaw.json:  ${OPENCLAW_CFG}"
[[ -n "$LATEST_BACKUP" ]] && echo "  Restored from:  $LATEST_BACKUP"
echo "  Audit log:      $HOME/.openclaw/clawlens/audit.jsonl  (preserved — rm manually if you want it gone)"
echo
