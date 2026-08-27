# ============================================================
#  git-sync.ps1
#  Everyday sync: pull, stage everything, commit, push.
#  Run setup-git-push.ps1 once first.
#
#  Usage:  .\git-sync.ps1
#          .\git-sync.ps1 "added Dhp ch.3 gloss"
# ============================================================

param([string]$Message)

$ErrorActionPreference = 'Continue'
$Vault = 'C:\Users\LENOVO\Obsidian\Dhammapada-rails'
Set-Location $Vault

function Say  ($m) { Write-Host $m -ForegroundColor Cyan }
function Fail ($m) { Write-Host "`nFAILED: $m`n" -ForegroundColor Red; Read-Host 'Press Enter to close'; exit 1 }

Say "`n=== Syncing Dhammapada-rails ===`n"

# --- pull first so we never push onto a stale base ------------
Say "Pulling..."
git pull --rebase --autostash origin main
if ($LASTEXITCODE -ne 0) {
    Fail "Pull/rebase hit a conflict. Resolve it, then run:  git rebase --continue`nSee 4-SYSTEM/How-to guides/How to Fix Git Merge Conflicts in Obsidian.md"
}

# --- anything to commit? --------------------------------------
$dirty = git status --porcelain
if ([string]::IsNullOrWhiteSpace($dirty)) {
    Say "`nNothing to commit - already up to date."
    Read-Host 'Press Enter to close'; exit 0
}

Write-Host ""
git status --short
Write-Host ""

if ([string]::IsNullOrWhiteSpace($Message)) {
    $stamp   = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $count   = ($dirty -split "`n" | Where-Object { $_ -ne '' }).Count
    $Message = "vault sync $stamp ($count file(s))"
}

git add -A
git commit -m "$Message"
if ($LASTEXITCODE -ne 0) { Fail "Commit failed." }

Say "`nPushing..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    Fail "Push failed. If it asked for credentials, re-run setup-git-push.ps1 - the token may have expired or been revoked."
}

Say "`nPushed: $Message"
Read-Host 'Press Enter to close'
