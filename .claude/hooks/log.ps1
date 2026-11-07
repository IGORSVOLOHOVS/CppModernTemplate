param([Parameter(Mandatory = $true)][string]$Event)
try {
    $in = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $line = [ordered]@{ ts = (Get-Date -Format o); event = $Event }
    if ($in.session_id) { $line.session = $in.session_id }
    if ($in.tool_name)  { $line.tool = $in.tool_name }
    foreach ($k in @('prompt', 'message', 'reason', 'source', 'file_path')) {
        if ($in.$k) {
            $s = "$($in.$k)"
            $line.detail = $s.Substring(0, [Math]::Min(200, $s.Length))
            break
        }
    }
    $dir = Join-Path $PSScriptRoot '..\logs'
    New-Item -ItemType Directory -Force $dir | Out-Null
    # one JSON line, no BOM (§1): a BOM fails a JSON-lines reader on line 1
    $file = [System.IO.Path]::GetFullPath((Join-Path $dir 'ai.jsonl'))
    $text = ($line | ConvertTo-Json -Compress) + "`n"
    $enc  = New-Object System.Text.UTF8Encoding $false
    # "file in use" (another hook appending) -> wait 10, 20, ... ms and retry, 20 tries
    for ($try = 0; $try -lt 20; $try++) {
        try { [System.IO.File]::AppendAllText($file, $text, $enc); break }
        catch [System.IO.IOException] { Start-Sleep -Milliseconds (10 * ($try + 1)) }
    }
} catch { }
exit 0
