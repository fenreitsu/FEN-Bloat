function Write-FBLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Module = "CORE")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Module] $Message"
    try {
        Add-Content -Path $script:LogPath -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    } catch { }
    $color = switch ($Level) { "INFO" {"Gray"}; "SUCCESS" {"Green"}; "ERROR" {"Red"}; "WARNING" {"Yellow"}; default {"White"} }
    Write-Host $logEntry -ForegroundColor $color
}

function Invoke-FBRegistryChange {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord", [string]$Description = "")
    try {
        if (-not (Test-Path "Registry::$Path")) { $null = New-Item -Path "Registry::$Path" -Force }
        $backup = $null
        try { $backup = (Get-ItemProperty -Path "Registry::$Path" -Name $Name -ErrorAction SilentlyContinue).$Name } catch { }
        $script:registryBackups += @{ Path=$Path; Name=$Name; OriginalValue=$backup; Description=$Description; Timestamp=(Get-Date -Format "yyyy-MM-dd HH:mm:ss") }
        Set-ItemProperty -Path "Registry::$Path" -Name $Name -Value $Value -Type $Type -Force
        Write-FBLog "Registry: $Path\$Name = $Value" -Level SUCCESS -Module REGISTRY
        return $true
    } catch {
        Write-FBLog "Registry error: $Path\$Name - $_" -Level ERROR -Module REGISTRY
        return $false
    }
}

function Save-FBRegistryBackups {
    $file = Join-Path $script:BackupPath "RegistryBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    try { $script:registryBackups | ConvertTo-Json -Depth 5 | Set-Content -Path $file -Encoding UTF8 } catch { }
}

function Test-FBAdministrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-FBAdministrator {
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $args
    exit
}

function Test-FBWinGet {
    try { $null = Get-Command winget -ErrorAction Stop; return $true } catch { return $false }
}
