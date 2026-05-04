# ClawLens Preview

ClawLens is an [OpenClaw](https://openclaw.ai/) plugin that watches every tool call your agents make, scores each one for risk, and surfaces what should worry you in a local dashboard. This repo hosts preview builds for selected users; the source is maintained separately.

You're seeing this because someone gave you the link directly. We're not advertising the preview broadly yet — feedback from a small group is shaping what ships next.

## What you get

- **Dashboard** at `http://localhost:18789/plugins/clawlens/` — agents, sessions, recent activity, risk scores
- **Tamper-evident audit log** at `~/.openclaw/clawlens/audit.jsonl` — every tool call, hash-chained
- **Risk scoring** — fast deterministic rules plus LLM evaluation for ambiguous calls (`exec`, novel writes, web fetches with sensitive context)
- **Telegram alerts** for high-risk events (off by default unless you have a Telegram channel paired with OpenClaw)

Everything runs locally. No data leaves your machine.

## Requirements

- macOS or Linux
- OpenClaw gateway already installed and running (verified on `2026.5.x`; should work on `2026.4.x` — both branches share the same plugin contract)
- `node` 22+, `npm`, `curl`, `jq`, `tar` on your `PATH`
- No GitHub authentication required — the install URL and tarball assets are publicly readable

## Read before installing

- **Bonjour crashloop**: some OpenClaw releases ship with a bonjour plugin that has a known crash bug. The installer aborts with an explicit fix command if bonjour isn't already disabled in your `openclaw.json`. Disable it once and you're good.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh | bash
```

Typically completes in 10–30 seconds depending on your network and `npm` cache state. If you'd like to read the script before running it (recommended for any `curl | bash` install):

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh -o /tmp/clawlens-install.sh
less /tmp/clawlens-install.sh
bash /tmp/clawlens-install.sh
```

The installer preflights every requirement, downloads + verifies the SHA-256 of the latest tarball, installs to `~/.clawlens-<version>/`, atomically registers the plugin in your `openclaw.json` (with a timestamped backup of the original), restarts the gateway, and polls `/plugins/clawlens/api/health` until ready. It aborts before any system change if anything is off — every error message includes the exact remediation command.

### Expected install output

```
ClawLens Preview — Installer
============================

→ Preflight checks...
→ Preflight passed.
→ Fetching latest release tag...
→ Latest release: v0.2.0-preview.1
→ Downloading tarball + checksum...
→ Verifying checksum...
→ Extracting to ~/.clawlens-0.2.0-preview.1...
→ Installing runtime dependencies (~30s)...
→ Updating symlink: ~/.clawlens → ~/.clawlens-0.2.0-preview.1
→ Backed up openclaw.json → ~/.openclaw/openclaw.json.bak.<timestamp>
→ Registering plugin with OpenClaw...
→ Restarting gateway...
→ Waiting for gateway to come up (up to 30s)...

✓ ClawLens v0.2.0-preview.1 is running.

  Dashboard:    http://localhost:18789/plugins/clawlens/
  Audit log:    ~/.openclaw/clawlens/audit.jsonl
  Install dir:  ~/.clawlens-0.2.0-preview.1  (symlinked from ~/.clawlens)
  Backup:       ~/.openclaw/openclaw.json.bak.<timestamp>

  Uninstall:    curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/uninstall.sh | bash
```

If the installer aborts, you'll see a `✗` line in red explaining what's wrong and the exact command to fix it before re-running.

### Verify it's running

```bash
curl -sS http://localhost:18789/plugins/clawlens/api/health
```

Expected JSON: `{"valid":true,"totalEntries":N,"lastEntryTimestamp":"..."}`. Then open the dashboard URL in your browser. See the bundled `PREVIEW.md` (inside the tarball) for usage details and configuration overrides.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/uninstall.sh | bash
```

Restores `openclaw.json` from the most recent installer-created backup, surgically removes any remaining ClawLens entries, deletes the `~/.clawlens` symlink and `~/.clawlens-*` install dirs, and restarts the gateway.

**Audit log at `~/.openclaw/clawlens/audit.jsonl` is preserved** — uninstall + reinstall is non-destructive; if you reinstall later, the next session picks up where you left off. Delete the audit log manually if you want it gone.

### Expected uninstall output

```
ClawLens Preview — Uninstaller
==============================

→ Restoring openclaw.json from ~/.openclaw/openclaw.json.bak.<timestamp>
→ Removing any remaining clawlens entries from openclaw.json...
→ Removing ~/.clawlens symlink and any ~/.clawlens-* dirs...
→ Restarting gateway...
→ Waiting for gateway (up to 30s)...

✓ ClawLens removed.

  openclaw.json:  ~/.openclaw/openclaw.json
  Restored from:  ~/.openclaw/openclaw.json.bak.<timestamp>
  Audit log:      ~/.openclaw/clawlens/audit.jsonl  (preserved — rm manually if you want it gone)
```

## What gets created on disk

After install:

- `~/.clawlens-<version>/` — versioned install directory (compiled JS + dashboard SPA + plugin manifest)
- `~/.clawlens` — symlink to the current versioned install
- `~/.openclaw/openclaw.json` — your existing OpenClaw config, with one ClawLens entry added
- `~/.openclaw/openclaw.json.bak.<timestamp>` — backup of `openclaw.json` from before the installer's edit
- `~/.openclaw/clawlens/audit.jsonl` — append-only audit log (created on first audited tool call)

Each install creates a fresh timestamped backup; older `openclaw.json.bak.*` files can be deleted at your discretion. Versioned install dirs (`~/.clawlens-<version>/`) accumulate across upgrades so prior versions remain on disk for manual rollback.

## Feedback

Reply on the DM thread you got the install link from — that's the feedback channel for this preview. Anything that surprised you (good or bad) is signal.

## License

See `LICENSE-NOTICE`. Preview builds are provided to selected users for evaluation only — not for redistribution.
