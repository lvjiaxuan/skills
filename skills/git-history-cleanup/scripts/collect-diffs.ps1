param(
    [Parameter(Mandatory=$true)][string]$StartHash,
    [string]$EndHash = "HEAD",
    [int]$MaxDiffLines = 40
)

# Collects per-commit diff summaries for the given range.
# Output: .git/commit-diffs.txt — one section per commit with stat + truncated diff.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File collect-diffs.ps1 -StartHash v1.11.0 -EndHash HEAD

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { Write-Error "Not inside a git repo"; exit 1 }

$gitDir = Join-Path $repoRoot ".git"
$outFile = Join-Path $gitDir "commit-diffs.txt"

# Get commit hashes in chronological order (oldest first)
$hashes = git rev-list --reverse "$StartHash..$EndHash"
if (-not $hashes) { Write-Error "No commits in range $StartHash..$EndHash"; exit 1 }

$sb = New-Object System.Text.StringBuilder

foreach ($h in $hashes) {
    $short = $h.Substring(0, 7)
    $subject = git log -1 --format="%s" $h

    [void]$sb.AppendLine("=" * 72)
    [void]$sb.AppendLine("COMMIT $short  |  $subject")
    [void]$sb.AppendLine("=" * 72)

    # Stat summary (files changed, insertions, deletions)
    $stat = git show --stat --format="" $h
    [void]$sb.AppendLine($stat)

    # Truncated diff (code changes only, skip binary)
    $diff = git show --format="" --no-color --diff-filter=d $h 2>$null |
            Select-Object -First $MaxDiffLines
    [void]$sb.AppendLine("--- diff (first $MaxDiffLines lines) ---")
    [void]$sb.AppendLine(($diff -join "`n"))
    [void]$sb.AppendLine("")
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outFile, $sb.ToString(), $utf8NoBom)

$count = @($hashes).Count
Write-Host "Collected diffs for $count commits -> $outFile"
