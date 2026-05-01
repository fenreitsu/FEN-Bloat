<#
.SYNOPSIS
    FEN-Bloat - Windows Utility & Debloater
.DESCRIPTION
    Modular debloat tool inspired by Win11Debloat and ChrisTitus WinUtil.
    Uses WPF GUI with XAML, dot-sources modular scripts.
.NOTES
    Version: 1.0.0
    Author: FEN-Bloat Team
    Compatibility: Windows 10 (1809+) and Windows 11 (21H2+)
    Requires: Administrator privileges
.EXAMPLE
    .\FEN-Bloat.ps1
    .\FEN-Bloat.ps1 -NoGUI -DisableTelemetry -InstallApps Chrome,7zip
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$NoGUI,
    [switch]$DisableTelemetry,
    [switch]$RemoveXboxApps,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableBingSearch,
    [switch]$EnableDarkMode,
    [switch]$ShowFileExtensions,
    [switch]$ClassicContextMenu,
    [switch]$DisableGameBar,
    [switch]$UpdateWinget,
    [string[]]$InstallApps,
    [switch]$InstallSelectedRecommended,
    [switch]$UpdateAllApps,
    [switch]$RepairWindowsUpdate,
    [switch]$RunSFCAndDISM,
    [switch]$CleanTemporaryFiles,
    [switch]$CreateRestorePoint,
    [string]$ImportAppList,
    [string]$ExportAppList,
    [switch]$ForceUpdate,
    [switch]$NoAutoUpdate
)

# ==============================================================================
# SCRIPT-LEVEL VARIABLES & PATHS
# ==============================================================================

$script:Version    = "1.0.0"
$script:PSScriptRootPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$script:AppName    = "FEN-Bloat"
$script:BasePath   = $script:PSScriptRootPath
$script:LogPath    = Join-Path $script:BasePath "Logs\FEN-Bloat.log"
$script:ConfigPath = Join-Path $script:BasePath "Config\LastUsed.json"
$script:BackupPath = Join-Path $script:BasePath "Backups"
$script:TempDir    = "$env:TEMP\FEN-Bloat"
$script:RepoOwner  = "fenreitsu"
$script:RepoName   = "FEN-Bloat"
$script:GitHubAPI  = "https://api.github.com/repos/$($script:RepoOwner)/$($script:RepoName)/releases/latest"

# Schema paths
$script:MainWindowSchema  = Join-Path $script:BasePath "Schemas\MainWindow.xaml"
$script:SharedStylesSchema = Join-Path $script:BasePath "Schemas\SharedStyles.xaml"
$script:FeaturesFilePath  = Join-Path $script:BasePath "Config\Features.json"
$script:AppsFilePath      = Join-Path $script:BasePath "Config\Apps.json"
$script:DefaultSettingsPath = Join-Path $script:BasePath "Config\DefaultSettings.json"

# Logo paths
$script:LogoDark  = Join-Path $script:BasePath "assets\fenreitsu-white.png"
$script:LogoLight = Join-Path $script:BasePath "assets\fenreitsu.png"

# Required directories
$requiredDirs = @($script:BasePath, (Join-Path $script:BasePath "Logs"), (Join-Path $script:BasePath "Config"), $script:BackupPath, $script:TempDir)
foreach ($dir in $requiredDirs) { if (-not (Test-Path $dir)) { $null = New-Item -Path $dir -ItemType Directory -Force } }

# Script-level state
$script:registryBackups = @()
$script:GuiWindow = $null
$script:currentTheme = "dark"
$script:FBCheckboxes = @{}
$script:FBInstallChecks = @{}
$script:FBTweakChecks = @{}
$script:MainProgressBar = $null
$script:UpdateCheckJob = $null

# ==============================================================================
# BLOATWARE APP LIST
# ==============================================================================

$script:BloatwareApps = @(
    @{ Name="Microsoft.XboxApp"; Label="Xbox Console Companion"; Category="Gaming" },
    @{ Name="Microsoft.XboxGameOverlay"; Label="Xbox Game Overlay"; Category="Gaming" },
    @{ Name="Microsoft.XboxGamingOverlay"; Label="Xbox Game Bar"; Category="Gaming" },
    @{ Name="Microsoft.XboxIdentityProvider"; Label="Xbox Identity Provider"; Category="Gaming" },
    @{ Name="Microsoft.XboxSpeechToTextOverlay"; Label="Xbox Speech To Text"; Category="Gaming" },
    @{ Name="Microsoft.Xbox.TCUI"; Label="Xbox TCUI"; Category="Gaming" },
    @{ Name="Microsoft.GamingApp"; Label="Xbox App (Nuevo)"; Category="Gaming" },
    @{ Name="Microsoft.SkypeApp"; Label="Skype"; Category="Social" },
    @{ Name="Microsoft.BingWeather"; Label="Bing Weather"; Category="Microsoft" },
    @{ Name="Microsoft.BingNews"; Label="Bing News"; Category="Microsoft" },
    @{ Name="Microsoft.BingSearch"; Label="Bing Search"; Category="Microsoft" },
    @{ Name="Microsoft.GetHelp"; Label="Get Help"; Category="Microsoft" },
    @{ Name="Microsoft.Getstarted"; Label="Get Started (Tips)"; Category="Microsoft" },
    @{ Name="Microsoft.Microsoft3DViewer"; Label="3D Viewer"; Category="Microsoft" },
    @{ Name="Microsoft.MicrosoftSolitaireCollection"; Label="Solitaire Collection"; Category="Games" },
    @{ Name="Microsoft.MicrosoftStickyNotes"; Label="Sticky Notes"; Category="Productivity" },
    @{ Name="Microsoft.MSPaint"; Label="Paint 3D"; Category="Microsoft" },
    @{ Name="Microsoft.Office.OneNote"; Label="OneNote"; Category="Office" },
    @{ Name="Microsoft.OneDrive"; Label="OneDrive"; Category="Cloud" },
    @{ Name="Microsoft.People"; Label="People"; Category="Social" },
    @{ Name="Microsoft.PowerAutomateDesktop"; Label="Power Automate"; Category="Microsoft" },
    @{ Name="Microsoft.Print3D"; Label="Print 3D"; Category="Microsoft" },
    @{ Name="Microsoft.Todos"; Label="To Do"; Category="Productivity" },
    @{ Name="Microsoft.WindowsAlarms"; Label="Alarms & Clock"; Category="Utilities" },
    @{ Name="Microsoft.WindowsCamera"; Label="Camera"; Category="Utilities" },
    @{ Name="microsoft.windowscommunicationsapps"; Label="Mail & Calendar"; Category="Microsoft" },
    @{ Name="Microsoft.WindowsFeedbackHub"; Label="Feedback Hub"; Category="Microsoft" },
    @{ Name="Microsoft.WindowsMaps"; Label="Maps"; Category="Utilities" },
    @{ Name="Microsoft.WindowsSoundRecorder"; Label="Sound Recorder"; Category="Utilities" },
    @{ Name="Microsoft.YourPhone"; Label="Phone Link"; Category="Microsoft" },
    @{ Name="Microsoft.ZuneMusic"; Label="Groove Music"; Category="Media" },
    @{ Name="Microsoft.ZuneVideo"; Label="Movies & TV"; Category="Media" },
    @{ Name="MicrosoftCorporationII.MicrosoftFamily"; Label="Microsoft Family"; Category="Microsoft" },
    @{ Name="Microsoft.MicrosoftOfficeHub"; Label="Office Hub"; Category="Office" },
    @{ Name="Clipchamp.Clipchamp"; Label="Clipchamp (Video)"; Category="Media" },
    @{ Name="Microsoft.549981C3F5F10"; Label="Cortana"; Category="Microsoft" },
    @{ Name="MicrosoftWindows.Client.WebExperience"; Label="Widgets"; Category="Microsoft" },
    @{ Name="king.com.CandyCrushSaga"; Label="Candy Crush Saga"; Category="Games" },
    @{ Name="king.com.CandyCrushSodaSaga"; Label="Candy Crush Soda"; Category="Games" }
)

$script:RecommendedRemovals = @(
    "Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.Xbox.TCUI",
    "Microsoft.SkypeApp","Microsoft.BingWeather","Microsoft.BingNews",
    "Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftSolitaireCollection","Microsoft.MSPaint","Microsoft.People",
    "Microsoft.PowerAutomateDesktop","Microsoft.Print3D","Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps","Microsoft.ZuneMusic","Microsoft.ZuneVideo",
    "MicrosoftCorporationII.MicrosoftFamily","Microsoft.549981C3F5F10",
    "MicrosoftWindows.Client.WebExperience","king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga","Clipchamp.Clipchamp"
)

# ==============================================================================
# INSTALLABLE APPS (from Config\Apps.json or fallback)
# ==============================================================================

if (Test-Path $script:AppsFilePath) {
    try {
        $appsJson = Get-Content $script:AppsFilePath -Raw | ConvertFrom-Json
        $script:AvailableApps = @{}
        foreach ($prop in $appsJson.Apps.PSObject.Properties) {
            $script:AvailableApps[$prop.Name] = @()
            foreach ($a in $prop.Value) {
                $script:AvailableApps[$prop.Name] += @{ Id=$a.Id; Name=$a.Name; Desc=$a.Desc; VersionUrl=$(if($a.VersionUrl){$a.VersionUrl}else{""}) }
            }
        }
    } catch { $script:AvailableApps = @{} }
} else {
    $script:AvailableApps = @{
        Essentials = @(
            @{Id="Google.Chrome";Name="Google Chrome";Category="Browser"},
            @{Id="Mozilla.Firefox";Name="Mozilla Firefox";Category="Browser"},
            @{Id="7zip.7zip";Name="7-Zip";Category="Archiver"},
            @{Id="Notepad++.Notepad++";Name="Notepad++";Category="Editor"},
            @{Id="Microsoft.PowerToys";Name="PowerToys";Category="Utility"},
            @{Id="Adobe.Acrobat.Reader.64-bit";Name="Adobe Reader";Category="PDF"}
        )
        Utilities = @(
            @{Id="CPUID.CPU-Z";Name="CPU-Z";Category="Diagnostics"},
            @{Id="CrystalDewWorld.CrystalDiskInfo";Name="CrystalDiskInfo";Category="Diagnostics"},
            @{Id="ShareX.ShareX";Name="ShareX";Category="Capture"},
            @{Id="voidtools.Everything";Name="Everything";Category="Search"},
            @{Id="Microsoft.WindowsTerminal";Name="Windows Terminal";Category="Terminal"}
        )
        Gaming = @(
            @{Id="Valve.Steam";Name="Steam";Category="Store"},
            @{Id="Discord.Discord";Name="Discord";Category="Chat"},
            @{Id="OBSProject.OBSStudio";Name="OBS Studio";Category="Streaming"},
            @{Id="Playnite.Playnite";Name="Playnite";Category="Launcher"}
        )
        DevTools = @(
            @{Id="Microsoft.VisualStudioCode";Name="VS Code";Category="IDE"},
            @{Id="Git.Git";Name="Git";Category="Version Control"},
            @{Id="Python.Python.3.12";Name="Python 3.12";Category="Language"},
            @{Id="Docker.DockerDesktop";Name="Docker Desktop";Category="Containers"},
            @{Id="Microsoft.dotnet";Name=".NET SDK";Category="Framework"}
        )
        Creative = @(
            @{Id="GIMP.GIMP";Name="GIMP";Category="Image"},
            @{Id="BlenderFoundation.Blender";Name="Blender";Category="3D"},
            @{Id="Audacity.Audacity";Name="Audacity";Category="Audio"},
            @{Id="VideoLAN.VLC";Name="VLC Media Player";Category="Media"},
            @{Id="HandBrake.HandBrake";Name="HandBrake";Category="Video"}
        )
        Social = @(
            @{Id="Discord.Discord";Name="Discord";Category="Chat"},
            @{Id="Zoom.Zoom";Name="Zoom";Category="Meetings"},
            @{Id="SlackTechnologies.Slack";Name="Slack";Category="Chat"}
        )
    }
}

# ==============================================================================
# DOT-SOURCE ALL MODULAR SCRIPTS
# ==============================================================================

# Core
. "$PSScriptRoot\Scripts\Core\Core-Functions.ps1"

# Debloat
. "$PSScriptRoot\Scripts\Debloat\Debloat-Functions.ps1"

# Install
. "$PSScriptRoot\Scripts\Install\Install-Functions.ps1"

# Tools
. "$PSScriptRoot\Scripts\Tools\Tools-Functions.ps1"

# GUI Helpers
. "$PSScriptRoot\Scripts\GUI\GUI-Helpers.ps1"

# Main Window
. "$PSScriptRoot\Scripts\GUI\Show-MainWindow.ps1"

# ==============================================================================
# CLI MODE
# ==============================================================================

function Invoke-FBCLIMode {
    Write-FBLog "CLI mode activated" -Level INFO -Module CORE
    $count = 0

    if ($DisableTelemetry) { Disable-FBTelemetry; $count++ }
    if ($RemoveXboxApps) {
        Remove-BloatwareApps -AppNames @("Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.Xbox.TCUI")
        $count++
    }
    if ($DisableCopilot) { Disable-FBCopilot; $count++ }
    if ($DisableRecall) { Disable-FBRecall; $count++ }
    if ($DisableBingSearch) { Disable-FBBingSearch; $count++ }
    if ($EnableDarkMode) { Enable-FBDarkMode; $count++ }
    if ($ShowFileExtensions) { Enable-FBFileExtensions; $count++ }
    if ($ClassicContextMenu) { Enable-FBClassicContextMenu; $count++ }
    if ($DisableGameBar) { Disable-FBGameBar; $count++ }
    if ($UpdateWinget) { try { Start-Process winget "source update" -Wait -NoNewWindow } catch { }; $count++ }
    if ($RepairWindowsUpdate) { Repair-FBWindowsUpdate; $count++ }
    if ($RunSFCAndDISM) { Run-FBSFCAndDISM; $count++ }
    if ($CleanTemporaryFiles) { Clear-FBTemporaryFiles; $count++ }
    if ($CreateRestorePoint) { Create-FBRestorePoint; $count++ }
    if ($InstallApps) { Install-FBApps -AppIds $InstallApps; $count++ }
    if ($ExportAppList) { Export-FBAppList -OutputPath $ExportAppList; $count++ }
    if ($ImportAppList) { Import-FBAppList -InputPath $ImportAppList; $count++ }
    if ($UpdateAllApps) { Update-FBAllApps; $count++ }

    if ($count -eq 0) {
        Write-Host "No actions specified. Run without params for GUI, or use -NoGUI with specific flags." -ForegroundColor Cyan
    }
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================

if (-not (Test-FBAdministrator)) {
    Write-Host "[$script:AppName] Requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting with elevated permissions..." -ForegroundColor Yellow
    Request-FBAdministrator
    exit
}

Write-FBLog "=== FEN-Bloat v$($script:Version) started ===" -Level INFO -Module CORE
Write-FBLog "User: $env:USERNAME | PC: $env:COMPUTERNAME" -Level INFO -Module CORE

# Verify required files exist
$requiredFiles = @($script:MainWindowSchema, $script:SharedStylesSchema)
$missing = $requiredFiles | Where-Object { -not (Test-Path $_) }
if ($missing.Count -gt 0) {
    Write-Error "Missing required files: $($missing -join ', ')"
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    $null = [System.Console]::ReadKey()
    exit
}

if (-not (Test-FBWinGet)) {
    Write-FBLog "WinGet not available. Install functions will be limited." -Level WARNING -Module CORE
}

# Route to CLI or GUI
if ($NoGUI -or $PSBoundParameters.Count -gt 0) {
    Invoke-FBCLIMode
} else {
    Show-FBMainWindow
}

Write-FBLog "=== FEN-Bloat finished ===" -Level INFO -Module CORE
