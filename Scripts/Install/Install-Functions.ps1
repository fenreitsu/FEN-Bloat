function Install-FBApps {
    param([string[]]$AppIds)
    if (-not (Test-FBWinGet)) { Write-FBLog "WinGet no disponible" -Level ERROR -Module INSTALL; return @{Success=0;Failed=0;Total=$AppIds.Count} }
    $total=$AppIds.Count; $ok=0; $fail=0; $i=0
    foreach ($id in $AppIds) {
        $i++
        try {
            $p = Start-Process -FilePath "winget" -ArgumentList "install --id `"$id`" --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait -PassThru
            if ($p.ExitCode -eq 0) { $ok++ } else { $fail++ }
        } catch { $fail++ }
    }
    return @{Success=$ok;Failed=$fail;Total=$total}
}

function Update-FBAllApps {
    try {
        $p = Start-Process -FilePath "winget" -ArgumentList "upgrade --all --silent --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait -PassThru
        return ($p.ExitCode -eq 0)
    } catch { return $false }
}

function Export-FBAppList {
    param([string]$OutputPath)
    try {
        $raw = winget list --accept-source-agreements 2>$null | Select-Object -Skip 3 | Where-Object { $_ -match '\S' }
        $list = @()
        foreach ($line in $raw) {
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 2) { $list += @{Id=$parts[0].Trim(); Name=$parts[1].Trim(); Version=(if($parts.Count-ge3){$parts[2].Trim()}else{"Unknown"})} }
        }
        $list | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8
        return $list
    } catch { return @() }
}

function Import-FBAppList {
    param([string]$InputPath)
    try {
        $list = Get-Content -Path $InputPath -Encoding UTF8 | ConvertFrom-Json
        return Install-FBApps -AppIds ($list | ForEach-Object { $_.Id })
    } catch { return @{Success=0;Failed=0;Total=0} }
}
