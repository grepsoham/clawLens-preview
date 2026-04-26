# clawLens-preview

Public distribution channel for closed-preview builds of ClawLens — an OpenClaw plugin shipped to selected users for evaluation. Source code lives in a separate private repo; only compiled tarballs are published here as GitHub Release assets.

## Scope

- `install.sh` / `uninstall.sh` — one-line `curl | bash` installer + mirror uninstaller
- `README.md` — public install/uninstall docs
- `LICENSE-NOTICE` — closed-preview terms
- GitHub Releases — host versioned tarballs + sha256 (not tracked in source)

## What NOT to do

- No references to the private source repo, internal architecture, team, or preview user list — this repo is public
- No claims about future features in user-facing copy (script output, README, release notes) — describe only what's verified to work today

## Editing the scripts

- Cross-platform (macOS + Linux). Detect via `uname`, branch on platform-specific service control.
- Preflight every check before any system change. Abort with the exact remediation command in the error message.
- Atomic file edits via `jq ... > /tmp/x && mv ...`. Restore 0600 perms after — the pipeline drops them.
- A user's `openclaw.json` typically contains plaintext gateway auth + channel bot tokens. Inspect structurally via jq paths/types, never dump raw contents.
- No interactive prompts (`curl | bash` has no TTY). Re-runs must be idempotent.
- In-script comments explain non-obvious jq patterns. Preserve them when refactoring.

## Releases

Tagged `vX.Y.Z-preview.N` with `--prerelease`. `install.sh` queries the `/releases` endpoint (not `/releases/latest`, which excludes prereleases). Assets may be `gh release upload --clobber`'d to an existing tag during pre-ship updates — release notes carry build date + source commit hash so build identity is traceable.

## Testing

`bash -n` for syntax. Synthesize jq fixtures inline for polymorphic branches. Full E2E requires a real OpenClaw gateway via `curl ... install.sh | bash`.
