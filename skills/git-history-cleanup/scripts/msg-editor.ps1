param([string]$CommitMsgFile)

# Counter-based message injection for reword commits.
# Each invocation writes the next message from the array.
# GIT_EDITOR invokes this instead of opening an editor.

# CUSTOMIZE: Replace with your target commit messages (in reword order)
$messages = @(
    "chore: your first reworded message",
    "feat: your second reworded message",
    "fix: your third reworded message"
)

# Path to counter file (must be absolute path)
$counterFile = Join-Path (Split-Path $CommitMsgFile -Parent | Split-Path -Parent) "reword-counter.txt"

if (Test-Path $counterFile) {
    $counter = [int](Get-Content $counterFile)
} else {
    $counter = 0
}

if ($counter -lt $messages.Length) {
    # CRITICAL: UTF-8 without BOM — Set-Content adds BOM in Windows PowerShell
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($CommitMsgFile, $messages[$counter], $utf8NoBom)
}

$counter++
$utf8NoBom2 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($counterFile, $counter.ToString(), $utf8NoBom2)
