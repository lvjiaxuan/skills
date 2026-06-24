param([string]$TodoFile)

# Copies the pre-written rebase plan to the todo file.
# GIT_SEQUENCE_EDITOR invokes this instead of opening an editor.
$planFile = Join-Path (Split-Path $TodoFile -Parent | Split-Path -Parent) "rebase-todo-plan.txt"
Copy-Item $planFile $TodoFile -Force
