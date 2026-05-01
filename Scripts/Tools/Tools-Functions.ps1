function Repair-FBWindowsUpdate {
    $svcs = @("wuauserv","cryptSvc","bits","msiserver")
    foreach ($s in $svcs) { try { Stop-Service $s -Force -ErrorAction SilentlyContinue } catch { } }
    foreach ($f in @("$env:SystemRoot\SoftwareDistribution","$env:SystemRoot\System32\catroot2")) {
        if (Test-Path $f) { try { Rename-Item $f "$f.old_$(Get-Date -Format 'yyyyMMdd')" -Force } catch { } }
    }
    foreach ($s in $svcs) { try { Start-Service $s -ErrorAction SilentlyContinue } catch { } }
}

function Run-FBSFCAndDISM {
    try { Start-Process "sfc" "/scannow" -NoNewWindow -Wait } catch { }
    try { Start-Process "DISM" "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait } catch { }
}

function Clear-FBTemporaryFiles {
    $folders = @($env:TEMP, $env:TMP, "$env:SystemRoot\Temp", "$env:SystemRoot\Prefetch", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache")
    $total = 0
    foreach ($f in $folders) {
        if (Test-Path $f) { try { Get-ChildItem $f -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } catch { } }
    }
}

function Create-FBRestorePoint {
    param([string]$Description = "FEN-Bloat Restore Point")
    try {
        $last = Get-ComputerRestorePoint | Sort-Object SequenceNumber -Descending | Select-Object -First 1
        if ($last) { $elapsed = (Get-Date) - [DateTime]$last.CreationTime; if ($elapsed.TotalMinutes -lt 60) { return $false } }
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS
        return $true
    } catch { return $false }
}

function Invoke-FBMicroWin {
    $msg = "MicroWin - Windows Personalizado`n`nEsta funcion permite crear una ISO de Windows personalizada.`nRequiere: ISO original, ~20GB espacio, DISM tools."
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($msg, "MicroWin Info", "OK", "Info") | Out-Null
}
