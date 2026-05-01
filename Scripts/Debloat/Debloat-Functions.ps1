function Remove-FBAppxPackage {
    param([string]$PackageName, [switch]$AllUsers)
    try {
        $pkgs = if ($AllUsers) { Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*$PackageName*" } } else { Get-AppxPackage | Where-Object { $_.Name -like "*$PackageName*" } }
        if (-not $pkgs) { return @{Success=$false; Message="Not found"} }
        $removed = 0
        foreach ($pkg in $pkgs) {
            try {
                if ($AllUsers) { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$PackageName*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue }
                $pkg | Remove-AppxPackage -ErrorAction SilentlyContinue
                $removed++
            } catch { }
        }
        return @{Success=($removed -gt 0); Removed=$removed}
    } catch { return @{Success=$false; Message=$_.Exception.Message} }
}

function Disable-FBTelemetry {
    Invoke-FBRegistryChange -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Description "Telemetria desactivada"
    try { Get-Service "DiagTrack" -ErrorAction SilentlyContinue | Stop-Service -Force; Set-Service "DiagTrack" -StartupType Disabled } catch { }
    try { Get-Service "dmwappushservice" -ErrorAction SilentlyContinue | Stop-Service -Force; Set-Service "dmwappushservice" -StartupType Disabled } catch { }
}

function Disable-FBCopilot {
    Invoke-FBRegistryChange -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Description "Copilot off"
    Invoke-FBRegistryChange -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Description "Copilot off (user)"
    Remove-FBAppxPackage -PackageName "Microsoft.Windows.Ai.Copilot.Provider" -AllUsers
}

function Disable-FBRecall {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "SettingEnabledForShellRecall" -Value 0
}

function Disable-FBBingSearch {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
    Invoke-FBRegistryChange -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
}

function Disable-FBWidgets {
    Invoke-FBRegistryChange -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0
}

function Disable-FBSuggestedNotifications {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0
}

function Disable-FBThirdPartyBgApps {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
}

function Disable-FBDeliveryOptimization {
    Invoke-FBRegistryChange -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0
}

function Disable-FBGameBar {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
    Invoke-FBRegistryChange -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    try { Get-Service "BcastDVRUserService" -ErrorAction SilentlyContinue | Stop-Service -Force; Set-Service "BcastDVRUserService" -StartupType Disabled } catch { }
}

function Enable-FBDarkMode {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0
}

function Enable-FBFileExtensions {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    try { (New-Object -ComObject Shell.Application).Windows() | ForEach-Object { $_.Refresh() } } catch { }
}

function Enable-FBClassicContextMenu {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -Type String
    try { Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Start-Sleep 2 } catch { }
}

function Disable-FBFastStartup {
    Invoke-FBRegistryChange -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0
}

function Disable-FBLockScreen {
    Invoke-FBRegistryChange -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1
}

function Enable-FBEndTask {
    Invoke-FBRegistryChange -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1
}
