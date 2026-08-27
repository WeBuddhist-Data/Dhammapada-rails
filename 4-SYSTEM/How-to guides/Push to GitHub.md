---
title: Push to GitHub
type: how-to
tags: [git, sync, setup]
---

# Push to GitHub

This vault is already a git repo pointed at `https://github.com/WeBuddhist/Dhammapada-rails.git`,
branch `main`. The only thing missing was stored credentials, so pushes failed.

## One-time setup

1. Create a token at **https://github.com/settings/personal-access-tokens**
   - Fine-grained token, resource owner **WeBuddhist**
   - Repository access: **Dhammapada-rails**
   - Permission: **Contents → Read and write**
   - (Fine-grained tokens on an org repo may need an org owner to approve them.)
2. Run `4-SYSTEM/scripts/setup-git-push.ps1` — right-click → *Run with PowerShell*.
3. Paste the token at the hidden prompt. It goes straight into Windows Credential
   Manager via `git credential approve`; it is not written to any file in this vault.

The script verifies access with `git ls-remote` before it finishes, so if it says
"authenticated", pushing works.

## Everyday use

**From Obsidian** — the Git plugin's *Commit-and-sync* command now pushes silently.
Bind it to a hotkey, or turn on auto-commit in the plugin settings.

**From a terminal** — `4-SYSTEM/scripts/git-sync.ps1`

```powershell
.\4-SYSTEM\scripts\git-sync.ps1
.\4-SYSTEM\scripts\git-sync.ps1 "added Dhp ch.3 gloss"
```

It pulls with `--rebase --autostash` first, then commits and pushes, so it never
pushes onto a stale base.

## Security notes

- **Never paste a token into a chat, a note, or a script.** If one leaks, revoke it
  immediately at https://github.com/settings/tokens and issue a new one.
- The token lives in Windows Credential Manager, not in this repo. `.gitignore`
  already excludes `.obsidian/plugins/obsidian-git/data.json`, which is where the
  Obsidian Git plugin would otherwise keep credentials.
- Give tokens an expiry (90 days is a reasonable default) and re-run
  `setup-git-push.ps1` when one lapses.

## When something breaks

| Symptom | Fix |
|---|---|
| Push prompts for a password | Token expired or revoked — re-run `setup-git-push.ps1` |
| `403` / `Permission denied` | Token lacks **Contents: Read and write**, or the org hasn't approved it |
| Rebase stops on a conflict | See *How to Fix Git Merge Conflicts in Obsidian* |
| `workspace.json` keeps reappearing | See *Solving the Obsidian Git workspace.json Tracking Issue* |
