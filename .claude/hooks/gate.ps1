param([Parameter(Mandatory = $true)][string]$Event)
# empty or non-JSON payload -> deny (below)
$in = $null
try { $in = [Console]::In.ReadToEnd() | ConvertFrom-Json -ErrorAction Stop } catch { $in = $null }

function Write-Log([string]$decision) {
    try {
        $line = [ordered]@{ ts = (Get-Date -Format o); event = $Event }
        if ($in.session_id) { $line.session = $in.session_id }
        if ($in.tool_name)  { $line.tool = $in.tool_name }
        if ($decision)      { $line.decision = $decision }
        $dir = Join-Path $PSScriptRoot '..\logs'
        New-Item -ItemType Directory -Force $dir | Out-Null
        $file = [System.IO.Path]::GetFullPath((Join-Path $dir 'ai.jsonl'))     # one JSON line, no BOM
        $text = ($line | ConvertTo-Json -Compress) + "`n"
        $enc  = New-Object System.Text.UTF8Encoding $false
        # "file in use" (another hook appending) -> wait 10, 20, ... ms and retry, 20 tries
        for ($try = 0; $try -lt 20; $try++) {
            try { [System.IO.File]::AppendAllText($file, $text, $enc); break }
            catch [System.IO.IOException] { Start-Sleep -Milliseconds (10 * ($try + 1)) }
        }
    } catch { }
}

function Deny([string]$why) {
    Write-Log 'deny'
    @{ hookSpecificOutput = @{
        hookEventName = 'PreToolUse'
        permissionDecision = 'deny'
        permissionDecisionReason = $why } } | ConvertTo-Json -Compress
    exit 0
}

if ($Event -eq 'PreToolUse' -and -not $in.tool_name) {
    Deny 'The gate could not read this tool call, so it cannot judge it.'
}

# 'cd build && rm -rf out' -> 'cd build ', ' rm -rf out': each segment judged alone
# echo "rm -rf /" -> allow (quoted text is data: the verb is echo)
function Split-Segments([string]$Text) {
    if (-not $Text) { return @() }
    return @([regex]::Split($Text, '(?:\|\||&&|;|\||&|\r?\n)') |
        Where-Object { $_ -and $_.Trim() })
}

# 'sudo GIT_TRACE=1 git push -f' -> 'git push -f'
function Get-Head([string]$Segment) {
    return [regex]::Replace($Segment.TrimStart(), '^(?:sudo\s+|env\s+|[A-Za-z_][A-Za-z0-9_]*=[^\s]*\s+)+', '')
}

# 'C:\Git\bin\git.exe push' -> 'git'; 'Remove-Item -Recurse x' -> 'remove-item'
function Get-Verb([string]$Segment) {
    $h = Get-Head $Segment
    if ($h -notmatch '^([^\s;|&<>]+)') { return '' }
    $tok = ($Matches[1] -split '[\\/]')[-1]
    return ($tok -replace '\.(exe|cmd|bat|ps1)$', '').ToLower()
}

# 'git -C repo -c a=b push --force' -> 'push'
function Get-GitSubcommand([string]$Segment) {
    if ((Get-Verb $Segment) -ne 'git') { return '' }
    $toks = @(@((Get-Head $Segment) -split '\s+') | Where-Object { $_ })
    $i = 1
    while ($i -lt $toks.Count) {
        $t = $toks[$i]
        if ($t -in @('-C', '-c', '--git-dir', '--work-tree', '--exec-path')) { $i += 2; continue }
        if ($t.StartsWith('-')) { $i += 1; continue }
        return $t.ToLower()
    }
    return ''
}

# '-rf' with 'rR' -> $true; '-Force' -> $false (not a short-flag bundle)
function Test-Bundle([string]$Segment, [string]$Chars) {
    foreach ($m in [regex]::Matches($Segment, '(?<!\S)-(?!-)([A-Za-z]{1,4})(?!\S)')) {
        foreach ($c in $Chars.ToCharArray()) {
            if ($m.Groups[1].Value.IndexOf($c) -ge 0) { return $true }
        }
    }
    return $false
}

# 'rm -r x', 'Remove-Item -Recurse x' -> $true; 'rm x' -> $false
function Test-Recursive([string]$Segment) {
    if ($Segment -match '(?i)(?<!\S)-{1,2}(Recurse|recursive)(?![-\w])') { return $true }
    return (Test-Bundle $Segment 'rR')
}

# rm -rf "$TEMP/claude/x" -> allow (the scratchpad)
# rm -rf "$TEMP/" or "$TEMP/../build" -> deny ($TEMP itself, or outside it)
function Test-InTemp([string]$Segment, [string]$Tool) {
    $temp = [System.IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    $base = if ($in.cwd) { "$($in.cwd)" } else { (Get-Location).Path }
    $paths = @(); $skip = $false
    foreach ($t in @(@((Get-Head $Segment).Trim() -split '\s+') | Select-Object -Skip 1)) {
        if ($skip) { $skip = $false; continue }
        if ($t -like '#*') { break }                    # 'x # note' -> path x only
        if ($t -match '^-(ErrorAction|ea|Filter|Include|Exclude)$') { $skip = $true; continue }
        if ($t -match '^(-|/[A-Za-z]$)') { continue }
        if ($t -match '^\d*[<>]') { continue }          # '2>/dev/null' -> not a path
        $paths += $t
    }
    if (-not $paths) { return $false }
    foreach ($p in $paths) {
        if ($Tool -eq 'PowerShell') {
            $p = $p -replace '^\$env:(TEMP|TMP)(?=[\\/]|$)', $env:TEMP
        } else {
            $p = $p -creplace '^(\$(TEMP|TMP)|\$\{(TEMP|TMP)\}|/tmp)(?=[\\/]|$)', $env:TEMP
            $p = $p -replace '^/([A-Za-z])/', '$1:/'     # '/c/Users/x' -> 'c:/Users/x'
        }
        # '$TEMP/x/*' -> '$TEMP/x'
        $p = $p -replace '[\\/][^\\/]*[*?][^\\/]*$', ''
        # '$TEMP/' -> '$TEMP', which is not under $TEMP -> deny
        try { $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($base, $p)).TrimEnd([char[]]'\/') }
        catch { return $false }
        if (-not $full.StartsWith($temp, [System.StringComparison]::OrdinalIgnoreCase)) { return $false }
    }
    return $true
}

# on test: 'git reset --hard origin/test' or '@{u}' -> $true (the realign: allow)
# on test: 'git reset --hard HEAD~1' -> $false (deny)
function Test-Realign([string]$Segment, [string]$Branch) {
    $toks = @(@($Segment.Trim() -split '\s+') | Where-Object { $_ })
    $at = [array]::IndexOf(@($toks | ForEach-Object { $_.ToLower() }), 'reset')
    if ($at -lt 0) { return $false }
    $to = @($toks | Select-Object -Skip ($at + 1) | Where-Object { -not $_.StartsWith('-') })
    return ($to.Count -eq 1 -and ($to[0] -ceq "origin/$Branch" -or $to[0] -in @('@{u}', '@{upstream}')))
}

if ($Event -eq 'PreToolUse') {
    $tool = $in.tool_name
    if ($tool -in @('Bash', 'PowerShell')) {
        # rm "-rf" build -> rm -rf build -> deny
        $cmd = ("$($in.tool_input.command)" -replace '["'']', '')
        $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
        $noDelete = 'Destructive recursive delete blocked. Delete narrowly, or ask the human. Under $env:TEMP, where your scratchpad is, it is not blocked.'
        foreach ($seg in (Split-Segments $cmd)) {
            $verb = Get-Verb $seg
            # bash -c "rm -rf build" -> rm -rf build -> deny (xargs, cmd, powershell alike)
            if ($verb -in @('xargs', 'bash', 'sh', 'cmd', 'powershell', 'pwsh')) {
                $seg = [regex]::Replace((Get-Head $seg), '(?i)^\S+(\s+(-c|/c|//c|-Command|-NoProfile|-NonInteractive|-ExecutionPolicy\s+\S+|-r|-0|-n\s*\d+))*\s+', '')
                $verb = Get-Verb $seg
            }
            # rm -rf build, Remove-Item -Recurse build, rd -Recurse build -> deny
            if ($verb -in @('rm', 'remove-item', 'ri', 'rimraf', 'rd', 'rmdir', 'del', 'erase') -and
                ($verb -eq 'rimraf' -or (Test-Recursive $seg)) -and -not (Test-InTemp $seg $tool)) {
                Deny $noDelete
            }
            # rd /s build -> deny
            if ($verb -in @('rd', 'del', 'erase', 'rmdir') -and
                $seg -match '(?<!\S)/[sS](?!\S)' -and -not (Test-InTemp $seg $tool)) {
                Deny $noDelete
            }
            $sub = Get-GitSubcommand $seg
            if ($sub -eq 'push') {
                # git push --force, -f, --mirror, git push origin +main -> deny
                # git push --force-with-lease -> allow
                if (($seg -match '(?<!\S)--(force|mirror)(?![-\w])') -or (Test-Bundle $seg 'f') -or
                    ($seg -match '(?<!\S)\+[A-Za-z0-9_/.*-]+(?=\s|:|$)')) {
                    Deny 'Force-push blocked. History on the server is shared history; --force-with-lease on your own branch is not blocked.'
                }
            }
            # on test/release: reset --hard, clean -f, commit --amend, rebase -> deny
            if ($branch -in @('test', 'release')) {
                $rewrite = switch ($sub) {
                    'reset'  { ($seg -match '(?<!\S)--hard(?![-\w])') -and -not (Test-Realign $seg $branch) }
                    'clean'  { (Test-Bundle $seg 'f') -or ($seg -match '(?<!\S)--force(?![-\w])') }
                    'commit' { $seg -match '(?<!\S)--amend(?![-\w])' }
                    'rebase' { $true }
                    'filter-branch' { $true }
                    default  { $false }
                }
                if ($rewrite) {
                    Deny "History rewrite blocked on '$branch'. History on a shared branch is never rewritten. To put '$branch' back where the server has it: git reset --hard origin/$branch"
                }
            }
        }
    }
    Write-Log $null
    exit 0
}

Write-Log $null
exit 0
