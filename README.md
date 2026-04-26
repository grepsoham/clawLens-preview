# ClawLens Preview

Preview builds of [ClawLens](https://openclaw.ai/) for selected users. Source code is maintained in a separate private repository.

## Install (macOS or Linux, OpenClaw gateway required)

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh | bash
```

If you'd like to read the script before running it (recommended for any `curl ... | bash` install):

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/install.sh -o /tmp/clawlens-install.sh
less /tmp/clawlens-install.sh
bash /tmp/clawlens-install.sh
```

The installer:
- Verifies preflight requirements (`node` 22+, `npm`, `curl`, `jq`, gateway running and responsive)
- Aborts cleanly with the exact remediation command if `openclaw.json` is JSON5-flavored or if bonjour is enabled (a known crashloop on OpenClaw 2026.4.x — see PREVIEW.md inside the tarball)
- Downloads the latest preview tarball from this repo's Releases, verifies its SHA-256 checksum
- Installs to `~/.clawlens-<version>/` and points `~/.clawlens` at it via symlink
- Backs up `~/.openclaw/openclaw.json` before any edit, then atomically registers the plugin
- Restarts the gateway and polls `/plugins/clawlens/api/health` until ready (up to 30 s)

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/grepsoham/clawLens-preview/main/uninstall.sh | bash
```

Restores `~/.openclaw/openclaw.json` from the most recent installer-created backup, surgically removes any remaining ClawLens entries, deletes the `~/.clawlens` symlink and `~/.clawlens-*` install dirs, and restarts the gateway. Audit log at `~/.openclaw/clawlens/audit.jsonl` is preserved.

## License

See `LICENSE-NOTICE`. Preview builds are provided to selected users for evaluation only — not for redistribution.
