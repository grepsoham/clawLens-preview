# ClawLens Preview

ClawLens is an [OpenClaw](https://openclaw.ai/) plugin that watches every tool call your agents make, scores each one for risk, and surfaces what should worry you in a local dashboard. This repo hosts preview builds for selected users; the source is maintained separately.

## What you get

- **Dashboard** at `http://localhost:18789/plugins/clawlens/` — agents, sessions, recent activity, risk scores
- **Tamper-evident audit log** at `~/.openclaw/clawlens/audit.jsonl` — every tool call, hash-chained
- **Risk scoring** — fast deterministic rules plus LLM evaluation for ambiguous calls (`exec`, novel writes, web fetches with sensitive context)
- **Telegram alerts** for high-risk events (off by default unless you have a Telegram channel paired with OpenClaw)

Everything runs locally. No data leaves your machine.

## Requirements

- macOS or Linux
- OpenClaw gateway already installed and running (verified on `2026.5.x`; expected to work on `2026.4.x` — both branches share the same plugin contract)
- `node` 22+, `npm`, `curl`, `jq`, `tar` on your `PATH`
- No GitHub authentication required — the install URL and tarball assets are publicly readable

## Read before installing

- **Bonjour crashloop**: OpenClaw's bundled `bonjour` plugin (mDNS network announce) can throw an unhandled promise rejection that puts the gateway into a ~22-second restart loop. The installer detects this precondition and aborts with the exact disable command before touching anything. If your gateway already has `plugins.entries.bonjour.enabled: false`, you're already past this.

## Install

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh | bash
```

Typically completes in 10–30 seconds depending on your network and `npm` cache state.

What the installer does:

- **Preflights every requirement** — `node` 22+, `npm`, `curl`, `tar`, `jq`, `openclaw.json` exists and is strict-JSON, gateway running and responsive, bonjour explicitly disabled
- **Downloads + verifies SHA-256** — aborts before any system change if the checksum doesn't match
- **Extracts to `~/.clawlens-<version>/`** and points `~/.clawlens` at it via an atomic symlink swap
- **Backs up `~/.openclaw/openclaw.json`** with a timestamped suffix before any edit
- **Atomically registers the plugin** — `jq` produces a new file, `mv` swaps it in, perms restored to `0600`
- **Restarts the gateway** and polls `/plugins/clawlens/api/health` until ready (up to 30 s)
- **Aborts loudly with rollback instructions** if anything goes wrong — every error message includes the exact command to fix it

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

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/uninstall.sh | bash
```

What the uninstaller does:

- **Restores `openclaw.json`** from the most recent installer-created backup
- **Surgically removes any remaining ClawLens entries** in case the backup is missing or partial
- **Deletes the `~/.clawlens` symlink and all `~/.clawlens-*` install dirs**
- **Restarts the gateway** and verifies `/plugins/clawlens/` returns `404`

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
