param([Parameter(Mandatory = $true)][string]$MsgFile)
# 'fix(core): x' + Signed-off-by -> pass
# 'Fix(core): x', 'fix: x', 'fix(core): x' without Signed-off-by -> refused
$root = (git rev-parse --show-toplevel)
$recipe = Get-Content -Encoding UTF8 (Join-Path $root 'recipe.ps1') -Raw

# recipe.ps1: $CommitScopes = @('core', 'ui') -> scopes core, ui
function Read-List([string]$Name) {
    $m = [regex]::Match($recipe, "(?m)^\s*\`$$Name\s*=\s*([^#\r\n]*)")
    if (-not $m.Success) { return @() }
    return @([regex]::Matches($m.Groups[1].Value, '[''"]([^''"]+)[''"]') |
        ForEach-Object { $_.Groups[1].Value })
}
$types  = Read-List 'CommitTypes'
$scopes = Read-List 'CommitScopes'
if (-not $types -or -not $scopes) {
    Write-Host 'recipe.ps1 names no $CommitTypes/$CommitScopes - the subject cannot be judged.'
    exit 1
}

# a message starting with a BOM (EF BB BF) -> refused
$bytes = [System.IO.File]::ReadAllBytes($MsgFile)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Write-Host 'The commit message starts with a UTF-8 byte-order mark (EF BB BF).'
    Write-Host 'Set-Content and Out-File -Encoding utf8 write one on PowerShell 5.1, and git -F passes it on.'
    Write-Host 'Commit with -m, or write the file with [System.IO.File]::WriteAllText and UTF8Encoding($false).'
    exit 1
}
$text = (New-Object System.Text.UTF8Encoding $false).GetString($bytes)
$subject = (@($text -split '\r?\n') | Where-Object { $_ -notmatch '^#' } | Select-Object -First 1)

# 'Merge branch x' while git merges (MERGE_HEAD) -> pass; typed by hand -> judged
# a revert -> judged: 'fix(core): revert the threading change', signed off
$merging = Test-Path (Join-Path (git rev-parse --git-dir) 'MERGE_HEAD')
if ($subject -cmatch '^Merge ' -and $merging) { exit 0 }

$alt   = (($types  | ForEach-Object { [regex]::Escape($_) }) -join '|')
$scope = (($scopes | ForEach-Object { [regex]::Escape($_) }) -join '|')
# 'Ci(ci): x' -> refused (-cnotmatch: case counts)
if ($subject -cnotmatch "^($alt)\(($scope)\): .+") {
    Write-Host "Bad commit subject: '$subject'"
    Write-Host "Wanted: <type>(<scope>): <what changed>, lower case"
    Write-Host "types:  $($types -join ' ')"
    Write-Host "scopes: $($scopes -join ' ')"
    Write-Host 'e.g.    fix(core): join the threads before leaving main'
    exit 1
}
# 'Signed-off-by: A <a@b.c>' as a trailer -> pass; in a '#' line or a sentence -> refused
$trailers = @(git interpret-trailers --parse $MsgFile)
if (-not ($trailers | Where-Object { $_ -match '^Signed-off-by: .+ <.+@.+>$' })) {
    Write-Host "Missing Signed-off-by - commit with 'git commit -s'."
    exit 1
}
exit 0
