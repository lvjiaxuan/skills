# Runner script — sets env vars and executes rebase in a single process.
# This avoids env var persistence issues between separate shell calls.

# CUSTOMIZE: Set the base commit hash (exclusive start of rebase range)
$baseHash = "v1.11.0"  # or a commit hash like "abc1234"

$repoRoot = "d:\Repos_gh\eslint-config"  # CUSTOMIZE: absolute path to repo

# Clean up counter from any previous run
Remove-Item -Path "$repoRoot\.git\reword-counter.txt" -ErrorAction SilentlyContinue

# Set editors — paths must be absolute
$scriptDir = "$repoRoot\.git"
$env:GIT_SEQUENCE_EDITOR = "powershell -NoProfile -ExecutionPolicy Bypass -File $scriptDir/seq-editor.ps1"
$env:GIT_EDITOR = "powershell -NoProfile -ExecutionPolicy Bypass -File $scriptDir/msg-editor.ps1"

Set-Location $repoRoot
git rebase -i $baseHash
