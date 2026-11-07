# stdin, one line per ref: <local ref> <local sha> <remote ref> <remote sha>
# push of wm-7/feat/x -> pass; wm-7/FEAT/x or my-branch -> refused
# push of test or from-*, or deleting a branch other than release -> not judged
# push of release without the override phrase and a Why: line -> refused
# push creating release (the first push) -> pass; deleting release -> refused
# git push origin HEAD:release while on test -> judged as release
# --no-verify skips this hook; release.yaml records such a push (§8)
$root = (git rev-parse --show-toplevel)
$recipeFile = Join-Path $root 'recipe.ps1'
if (-not (Test-Path $recipeFile)) {
    Write-Host 'recipe.ps1 is missing - branch names are not judged here; the propose gate judges them.'
    exit 0
}
$recipe = Get-Content -Encoding UTF8 $recipeFile -Raw

$m = [regex]::Match($recipe, '(?m)^\s*\$Code\s*=\s*[''"]([^''"]+)[''"]')
if (-not $m.Success) {
    Write-Host 'recipe.ps1 names no $Code - the branch grammar cannot be judged.'
    exit 1
}
$code = $m.Groups[1].Value

# "$BranchTypes = @('feat', 'fix')" -> feat, fix
# "$BranchTypes = $CommitTypes + @('hotfix')" -> not a literal list -> warn, push not judged
$b = [regex]::Match($recipe, '(?m)^\s*\$BranchTypes\s*=\s*([^#\r\n]+)')
$types = @()
if ($b.Success) {
    if ($b.Groups[1].Value.Contains('$')) {
        Write-Host 'recipe.ps1: $BranchTypes must be one literal list of quoted names - branch names are not judged here.'
        exit 0
    }
    $types = @([regex]::Matches($b.Groups[1].Value, '[''"]([^''"]+)[''"]') |
        ForEach-Object { $_.Groups[1].Value })
}
if (-not $types) {
    Write-Host 'recipe.ps1 names no $BranchTypes - the branch grammar cannot be judged.'
    exit 1
}
$alt = ($types | ForEach-Object { [regex]::Escape($_) }) -join '|'
# case counts: wm-7/FEAT/x -> refused; FROM-x -> judged, not skipped as from-*
$re = "^$([regex]::Escape($code))-[1-9][0-9]*/($alt)/[a-z0-9]+(-[a-z0-9]+)*$"

$p = [regex]::Match($recipe, '(?m)^\s*\$OverridePhrase\s*=\s*[''"]([^''"]+)[''"]')
$phrase = ''
if ($p.Success) { $phrase = $p.Groups[1].Value }

$bad = $false
foreach ($line in $input) {
    $parts = @("$line".Trim() -split '\s+')
    if ($parts.Count -lt 4) { continue }
    $remote = $parts[2]
    if ($remote -notlike 'refs/heads/*') { continue }   # refs/tags/v1.0.0 -> not judged
    $branch = $remote.Substring('refs/heads/'.Length)
    if ($branch -ceq 'release') {
        if ($parts[1] -match '^0+$') {
            Write-Host 'release is never deleted.'
            $bad = $true
            continue
        }
        if ($parts[3] -match '^0+$') { continue }       # remote sha 000... -> release created -> pass
        if (-not $phrase) {
            Write-Host 'recipe.ps1 names no $OverridePhrase - a push to release cannot be judged. Open a pull request from test.'
            $bad = $true
            continue
        }
        $range = "$($parts[3])..$($parts[1])"
        $shas = @(git rev-list --first-parent $range --not refs/remotes/origin/test)
        if ($LASTEXITCODE -ne 0) {
            Write-Host "git cannot read $range against origin/test - fetch first, then push again."
            $bad = $true
            continue
        }
        $marked = $false
        $onItsOwn = "(?m)^\s*$([regex]::Escape($phrase))\s*$"     # '1234567890' alone on a line -> counts
        foreach ($sha in $shas) {
            $body = (git log -1 --format=%B $sha) -join "`n"
            if ($body -cmatch $onItsOwn -and $body -cmatch '(?m)^Why: \S') { $marked = $true }
        }
        if (-not $marked) {
            Write-Host "A push to release is the owner's override (BEST_REQUIREMENTS.md #8): one commit"
            Write-Host "you push must carry the override phrase and a 'Why: <reason>' line."
            Write-Host 'Otherwise open a pull request from test.'
            $bad = $true
        }
        continue
    }
    if ($parts[1] -match '^0+$') { continue }           # local sha 000... -> a deletion -> pass
    if ($branch -ceq 'test' -or $branch -clike 'from-*') { continue }
    if ($branch -cnotmatch $re) {
        Write-Host "Branch '$branch' violates $code-<issue>/<type>/<slug>, e.g. $code-7/feat/scanner-timeout"
        Write-Host 'Work starts from an issue, and the branch says which.'
        $bad = $true
    }
}
if ($bad) { exit 1 }
exit 0
