function Install-FBApps {
    param([string[]]$AppIds)
    if (-not (Test-FBWinGet)) { Write-FBLog "WinGet no disponible" -Level ERROR -Module INSTALL; return @{Success=0;Failed=0;Total=$AppIds.Count} }
    $total=$AppIds.Count; $ok=0; $fail=0; $i=0
    foreach ($id in $AppIds) {
        $i++
        if ($script:InstallStatusText) {
            $script:InstallStatusText.Dispatcher.Invoke([action]{ $script:InstallStatusText.Text = "Installing $id ($i/$total)..." })
        }
        Write-Host "Installing $id ($i/$total)..."
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "winget"
            $psi.Arguments = "install --id `"$id`" --silent --accept-package-agreements --accept-source-agreements"
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true
            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi
            $outEvent = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action {
                if ($Event.SourceEventArgs.Data) { Write-Host $Event.SourceEventArgs.Data }
            }
            $errEvent = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
                if ($Event.SourceEventArgs.Data) { Write-Host "ERROR: $($Event.SourceEventArgs.Data)" }
            }
            $proc.Start() | Out-Null
            $proc.BeginOutputReadLine()
            $proc.BeginErrorReadLine()
            $proc.WaitForExit()
            Unregister-Event -SubscriptionId $outEvent.Id -ErrorAction SilentlyContinue
            Unregister-Event -SubscriptionId $errEvent.Id -ErrorAction SilentlyContinue
            if ($proc.ExitCode -eq 0) { $ok++; Write-Host "  -> $id installed successfully" }
            else { $fail++; Write-Host "  -> $id installation failed (exit code: $($proc.ExitCode))" }
        } catch {
            $fail++
            Write-Host "  -> Error installing $id : $_"
        }
    }
    if ($script:InstallStatusText) {
        $script:InstallStatusText.Dispatcher.Invoke([action]{ $script:InstallStatusText.Text = "$ok/$total installed, $fail failed" })
    }
    Write-Host "Installation complete: $ok/$total installed, $fail failed"
    return @{Success=$ok;Failed=$fail;Total=$total}
}

function Update-FBAllApps {
    try {
        Write-Host "Upgrading all apps..."
        if ($script:InstallStatusText) {
            $script:InstallStatusText.Dispatcher.Invoke([action]{ $script:InstallStatusText.Text = "Upgrading all apps..." })
        }
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "winget"
        $psi.Arguments = "upgrade --all --silent --accept-package-agreements --accept-source-agreements"
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $outEvent = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action {
            if ($Event.SourceEventArgs.Data) { Write-Host $Event.SourceEventArgs.Data }
        }
        $errEvent = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
            if ($Event.SourceEventArgs.Data) { Write-Host "ERROR: $($Event.SourceEventArgs.Data)" }
        }
        $proc.Start() | Out-Null
        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()
        $proc.WaitForExit()
        Unregister-Event -SubscriptionId $outEvent.Id -ErrorAction SilentlyContinue
        Unregister-Event -SubscriptionId $errEvent.Id -ErrorAction SilentlyContinue
        if ($script:InstallStatusText) {
            $script:InstallStatusText.Dispatcher.Invoke([action]{ $script:InstallStatusText.Text = "Upgrade complete" })
        }
        Write-Host "Upgrade complete"
        return ($proc.ExitCode -eq 0)
    } catch {
        Write-Host "Error during upgrade: $_"
        return $false
    }
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
