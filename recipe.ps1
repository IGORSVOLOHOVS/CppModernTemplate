param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('build', 'install', 'uninstall', 'clean', 'run', 'publish', 'info', 'test')]
    [string]$Verb,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RunArgs
)

$Name    = 'cpp-modern-template'   # the repository
$Code    = 'cmt'                      # the project code; the first word of every branch
$Version = '1.0.0'   # what this repository versions
$Summary = 'A C++20 Makefile template for MinGW with an OpenGL example program, 2023.'
$Needs   = @()
$Tools   = @()

# No $App, $Entry, $Console, $Include or $Imports: nothing is installed.
$Provides = @()                      # and nothing is given to another project

$CommitTypes  = @('feat', 'fix', 'docs', 'refactor', 'test', 'build', 'ci', 'chore')
$CommitScopes = @('core', 'build', 'ci', 'docs', 'deps')
$BranchTypes  = @('feat', 'fix', 'docs', 'refactor', 'test', 'build', 'ci', 'chore', 'hotfix', 'experiment')
$Reviewers    = @('igors')  # first name is the owner; add a deputy where one exists
$OverridePhrase = '1234567890'   # §8 - the owner's override; a mark, not a password

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# The repository's keys (R-02), so every verb has them. A variable that is
# already set wins: the runner's env: and your own shell go over the file.
$envFile = Join-Path $PSScriptRoot '.claude\.env'
if (Test-Path $envFile) {
    foreach ($line in Get-Content -Encoding UTF8 $envFile) {
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$' -and
            -not (Test-Path "env:$($Matches[1])")) {
            Set-Item "env:$($Matches[1])" $Matches[2].Trim('"', "'")
        }
    }
}

switch ($Verb) {
    'test' {
        git -C $root config core.hooksPath .claude/hooks/git
        if ($LASTEXITCODE -ne 0) { exit 1 }
        # The folders that carry scripts; the tests live next to what they test.
        $scripts = @(Join-Path $root '.claude')
        python -m pytest $scripts
        # 5: no tests collected - a repository of documents may carry none yet
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 5) { exit 1 }
        python -m ruff check $scripts
        if ($LASTEXITCODE -ne 0) { exit 1 }
        # In place, never --check: the gate's git diff --exit-code is the check.
        python -m ruff format $scripts
        if ($LASTEXITCODE -ne 0) { exit 1 }
        exit 0
    }
    'info' {
        "Name    : $Name"
        "Code    : $Code"
        "Version : $Version"
        "Summary : $Summary"
        exit 0
    }
    'clean' {
        $junk = @(Get-ChildItem $root -Recurse -Force -Directory |
            Where-Object { $_.Name -in '__pycache__', '.pytest_cache', '.ruff_cache' })
        $junk | Remove-Item -Recurse -Force
        exit 0
    }
    default {
        # build, install, uninstall, run, publish
        Write-Host "nothing to $Verb"
        exit 0
    }
}
