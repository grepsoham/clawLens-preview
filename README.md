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
- OpenClaw gateway already installed and running (preview targets `2026.4.x`)
- `node` 22+, `npm`, `curl`, `jq`, `tar` on your `PATH`

## Read before installing

- **Bonjour crashloop**: OpenClaw 2026.4.x ships with a bonjour plugin that has a known crash bug. The installer aborts with an explicit fix command if bonjour isn't already disabled in your `openclaw.json`. Disable it once and you're good.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh | bash
```

About 90 seconds end to end. Always smart to read a `curl | bash` first:

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh -o /tmp/clawlens-install.sh
less /tmp/clawlens-install.sh
bash /tmp/clawlens-install.sh
```

The installer preflights every requirement, downloads + verifies the SHA-256 of the latest tarball, installs to `~/.clawlens-<version>/`, atomically registers the plugin in your `openclaw.json` (with a timestamped backup of the original), restarts the gateway, and polls `/plugins/clawlens/api/health` until ready. It aborts before any system change if anything is off.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/uninstall.sh | bash
```

Restores `openclaw.json` from the installer's backup, removes the `~/.clawlens` symlink and `~/.clawlens-*` dirs, restarts the gateway. Audit log at `~/.openclaw/clawlens/audit.jsonl` is preserved.

## Feedback

Reply on the DM thread you got the install link from — that's the feedback channel for this preview. Anything that surprised you (good or bad) is signal.

## License

See `LICENSE-NOTICE`. Preview builds are provided to selected users for evaluation only — not for redistribution.
