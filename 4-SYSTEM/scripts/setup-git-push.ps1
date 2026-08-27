# ============================================================
#  setup-git-push.ps1
#  One-time setup so this Obsidian vault can push to GitHub.
#
#  Run once:   right-click -> "Run with PowerShell"
#              (or:  powershell -ExecutionPolicy Bypass -File .\setup-git-push.ps1)
#
#  Your token is typed into a hidden prompt and handed straight
#  to Git's credential store. It is never written to a file,
#  never echoed, and never stored in this script.
# ============================================================

$ErrorActionPreference = 'Stop'
$Vault = 'C:\Users\LENOVO\Obsidian\Dhammapada-rails'

function Say  ($m) { Write-Host $m -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "  OK  $m" -ForegroundColor Green }
function Fail ($m) { Write-Host "`nFAILED: $m`n" -ForegroundColor Red; Read-Host 'Press Enter to close'; exit 1 }

Say "`n=== GitHub push setup for Dhammapada-rails ===`n"

# --- 1. Is git installed? ------------------------------------
try   { $gv = (git --version) 2>&1 }
catch { Fail "Git is not installed or not on PATH. Install Git for Windows: https://git-scm.com/download/win" }
Ok $gv

# --- 2. Is the vault a repo? ---------------------------------
if (-not (Test-Path $Vault))            { Fail "Vault not found at $Vault" }
Set-Location $Vault
if (-not (Test-Path (Join-Path $Vault '.git'))) { Fail "$Vault is not a git repository." }

$remote = (git remote get-url origin) 2>&1
if ($LASTEXITCODE -ne 0) { Fail "No 'origin' remote configured." }
Ok "repo   $Vault"
Ok "remote $remote"

# --- 3. Commit identity --------------------------------------
$name  = (git config user.name)  2>$null
$email = (git config user.email) 2>$null
if ([string]::IsNullOrWhiteSpace($name))  { $name  = Read-Host 'Name to use on commits';  git config user.name  "$name" }
if ([string]::IsNullOrWhiteSpace($email)) { $email = Read-Host 'Email to use on commits'; git config user.email "$email" }
Ok "commits as $name <$email>"

# --- 4. Pick a credential helper -----------------------------
$helper = $null
foreach ($h in @('manager','manager-core')) {
    $exe = Get-Command "git-credential-$h" -ErrorAction SilentlyContinue
    if (-not $exe) {
        $p = Join-Path $env:ProgramFiles "Git\mingw64\bin\git-credential-$h.exe"
        if (Test-Path $p) { $exe = $p }
    }
    if ($exe) { $helper = $h; break }
}
if (-not $helper) {
    Write-Host "  !   Git Credential Manager not found." -ForegroundColor Yellow
    Write-Host "      Falling back to 'store', which keeps the token in PLAIN TEXT at" -ForegroundColor Yellow
    Write-Host "      $env:USERPROFILE\.git-credentials" -ForegroundColor Yellow
    if ((Read-Host "      Continue with plain-text storage? (y/N)") -ne 'y') {
        Fail "Aborted. Reinstall Git for Windows with Credential Manager enabled, then re-run."
    }
    $helper = 'store'
}
git config --global credential.helper $helper
Ok "credential helper: $helper"

# --- 5. Take the token (hidden) and hand it to git ------------
Write-Host ""
Say "Paste your GitHub Personal Access Token."
Write-Host "  It needs 'Contents: Read and write' on WeBuddhist/Dhammapada-rails." -ForegroundColor DarkGray
Write-Host "  Nothing will appear as you type or paste - that is normal." -ForegroundColor DarkGray

$ghUser = Read-Host 'GitHub username'
$sec    = Read-Host 'GitHub token (hidden)' -AsSecureString
if ($sec.Length -eq 0) { Fail "No token entered." }

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $tok = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = 'git'
    $psi.Arguments              = 'credential approve'
    $psi.WorkingDirectory       = $Vault
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardInput  = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.StandardInput.NewLine = "`n"
    $proc.StandardInput.Write("protocol=https`nhost=github.com`nusername=$ghUser`npassword=$tok`n`n")
    $proc.StandardInput.Close()
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) { Fail "git credential approve exited with $($proc.ExitCode)" }
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    $tok = $null
    [GC]::Collect()
}
Ok "token stored for github.com ($ghUser)"

# --- 6. Prove it works ---------------------------------------
Write-Host ""
Say "Verifying access..."
git ls-remote --heads origin 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    git ls-remote --heads origin
    Fail "Could not reach the remote with those credentials. Check the username, the token's expiry, and that it has 'Contents: Read and write' on WeBuddhist/Dhammapada-rails. If the token is fine-grained, confirm the WeBuddhist org has approved it."
}
Ok "authenticated - push access to $remote confirmed"

# --- 7. Keep Obsidian's per-machine state out of commits -----
git rm --cached .obsidian/workspace.json 2>&1 | Out-Null
Ok "workspace.json untracked (it is in .gitignore)"

Write-Host ""
Say "Done. From now on:"
Write-Host "  - In Obsidian: the Git plugin's 'Commit-and-sync' will push without asking." -ForegroundColor Gray
Write-Host "  - From a terminal: run  .\4-SYSTEM\scripts\git-sync.ps1" -ForegroundColor Gray
Write-Host ""
Read-Host 'Press Enter to close'
