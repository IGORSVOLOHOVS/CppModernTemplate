param([Parameter(Mandatory = $true)][string]$Event)
$ErrorActionPreference = 'SilentlyContinue'
$in = [Console]::In.ReadToEnd() | ConvertFrom-Json
$root = Split-Path (Split-Path $PSScriptRoot)
$logDir = Join-Path $PSScriptRoot '..\logs'
$logFile = Join-Path $logDir 'ai.jsonl'

function Write-Log([hashtable]$extra) {
    try {
        $line = [ordered]@{ ts = (Get-Date -Format o); event = $Event }
        if ($in.session_id) { $line.session = $in.session_id }
        foreach ($k in $extra.Keys) { $line[$k] = $extra[$k] }
        New-Item -ItemType Directory -Force $logDir | Out-Null
        $file = [System.IO.Path]::GetFullPath($logFile)                        # one JSON line, no BOM
        $text = ($line | ConvertTo-Json -Compress) + "`n"
        $enc  = New-Object System.Text.UTF8Encoding $false
        # "file in use" (another hook appending) -> wait 10, 20, ... ms and retry, 20 tries
        for ($try = 0; $try -lt 20; $try++) {
            try { [System.IO.File]::AppendAllText($file, $text, $enc); break }
            catch [System.IO.IOException] { Start-Sleep -Milliseconds (10 * ($try + 1)) }
        }
    } catch { }
}

switch ($Event) {
    'SessionStart' {
        # ai.jsonl over 10 MB -> ai.jsonl.<yyyyMMddHHmmss>.bak
        if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt 10MB)) {
            Move-Item $logFile "$logFile.$(Get-Date -Format yyyyMMddHHmmss).bak" -Force
        }
        # core.hooksPath -> .claude/hooks/git; logged as hooks=path-set or hooks=failed
        $hooks = 'failed'
        if (Test-Path (Join-Path $PSScriptRoot 'git')) {
            git -C $root config core.hooksPath .claude/hooks/git | Out-Null
            if ($LASTEXITCODE -eq 0) { $hooks = 'path-set' }
        }
        if (-not (Test-Path (Join-Path $root 'recipe.ps1'))) {
            [Console]::Error.WriteLine('recipe.ps1 is missing - a lab project without a recipe is not set up')
        }
        $branch = (git -C $root rev-parse --abbrev-ref HEAD 2>$null)
        $issue = ''
        if ($branch -match '^[a-z][a-z0-9]*-([1-9][0-9]*)/') { $issue = $Matches[1] }
        Write-Log @{ detail = "branch=$branch issue=$issue hooks=$hooks" }
        @{ hookSpecificOutput = @{
            hookEventName = 'SessionStart'
            additionalContext = "Branch: $branch. Issue: $(if ($issue) { "#$issue" } else { 'none - work starts from an issue (BEST_REQUIREMENTS.md #4)' })." } } |
            ConvertTo-Json -Compress
    }
    'Stop' {
        Write-Log @{ detail = 'turn finished' }
    }
    'SessionEnd' {
        Write-Log @{ detail = "session ended: $($in.reason)" }
    }
}
exit 0
