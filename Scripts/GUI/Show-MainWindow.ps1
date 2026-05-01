function Show-FBMainWindow {
    Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase | Out-Null

    $usesDark = Get-FBSystemUsesDarkMode

    # Build a merged XAML file in temp so both files exist side-by-side
    $tempDir = Join-Path $env:TEMP "FENBloat_$(Get-Random)"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    $tempMain = Join-Path $tempDir "FENBloat_MainWindow.xaml"
    $tempShared = Join-Path $tempDir "SharedStyles.xaml"
    
    Copy-Item -Path $script:SharedStylesSchema -Destination $tempShared -Force
    
    $xaml = Get-Content -Path $script:MainWindowSchema -Raw
    [System.IO.File]::WriteAllText($tempMain, $xaml, [System.Text.Encoding]::UTF8)
    
    # Load with FileStream + ParserContext (BaseUri enables relative URI resolution)
    try {
        $stream = [System.IO.FileStream]::new($tempMain, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $parserContext = New-Object System.Windows.Markup.ParserContext
        $parserContext.BaseUri = [System.Uri]::new("file:///$([System.IO.Path]::GetFullPath($tempMain) -replace '\\', '/')")
        $window = [System.Windows.Markup.XamlReader]::Load($stream, $parserContext)
    } finally {
        if ($stream) { $stream.Close() }
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($null -eq $window) {
        Write-Error "Failed to load MainWindow.xaml. Check XAML syntax."
        return
    }

    Set-WPFWindowTheme -window $window -usesDarkMode $usesDark
    $script:GuiWindow = $window
    $script:currentTheme = if ($usesDark) { "dark" } else { "light" }

    # Get controls
    $mainBorder       = $window.FindName("MainBorder")
    $titleBarBg       = $window.FindName("TitleBarBackground")
    $themeBtn         = $window.FindName("ThemeToggleBtn")
    $closeBtn         = $window.FindName("CloseBtn")
    $logoImg          = $window.FindName("LogoImage")
    $verText          = $window.FindName("VersionText")
    $mainProgress     = $window.FindName("MainProgressBar")
    $script:MainProgressBar = $mainProgress

    $tabControl       = $window.FindName("MainTabControl")
    $tabDebloat       = $window.FindName("TabDebloat")
    $tabInstall       = $window.FindName("TabInstall")
    $tabTweaks        = $window.FindName("TabTweaks")
    $tabTools         = $window.FindName("TabTools")

    # Panels
    $appPanel         = $window.FindName("AppRemovalPanel")
    $privacyPanel     = $window.FindName("PrivacyPanel")
    $aiPanel          = $window.FindName("AIPanel")
    $interfacePanel   = $window.FindName("InterfacePanel")
    $gamingPanel      = $window.FindName("GamingPanel")
    $systemPanel      = $window.FindName("SystemPanel")

    $installEssPanel  = $window.FindName("InstallEssentialsPanel")
    $installUtilPanel = $window.FindName("InstallUtilitiesPanel")
    $installGamPanel  = $window.FindName("InstallGamingPanel")
    $installDevPanel  = $window.FindName("InstallDevPanel")
    $installCrePanel  = $window.FindName("InstallCreativePanel")

    $tweaksPrivPanel  = $window.FindName("TweaksPrivacyPanel")
    $tweaksSysPanel   = $window.FindName("TweaksSystemPanel")
    $tweaksExpPanel   = $window.FindName("TweaksExplorerPanel")
    $tweaksAIPanel    = $window.FindName("TweaksAIPanel")
    $tweaksTaskPanel  = $window.FindName("TweaksTaskbarPanel")

    # Buttons
    $debloatApply     = $window.FindName("DebloatApplyBtn")
    $debloatAll       = $window.FindName("DebloatSelectAllBtn")
    $debloatRec       = $window.FindName("DebloatSelectRecommendedBtn")

    $installApply     = $window.FindName("InstallApplyBtn")
    $installUpdateAll = $window.FindName("InstallUpdateAllBtn")

    $tweaksApply      = $window.FindName("TweaksApplyBtn")

    $toolRepairWU     = $window.FindName("ToolRepairWU")
    $toolSFC          = $window.FindName("ToolSFC")
    $toolCleanTemp    = $window.FindName("ToolCleanTemp")
    $toolRestorePt    = $window.FindName("ToolRestorePoint")
    $toolMicroWin     = $window.FindName("ToolMicroWin")

    # Load logo
    $logoPath = if ($usesDark -and (Test-Path $script:LogoDark)) { $script:LogoDark } elseif ((Test-Path $script:LogoLight)) { $script:LogoLight } else { $null }
    if ($logoPath) {
        try {
            $bmp = [System.Windows.Media.Imaging.BitmapImage]::new()
            $bmp.BeginInit()
            $bmp.UriSource = [System.Uri]::new($logoPath, [System.UriKind]::Absolute)
            $bmp.EndInit()
            $logoImg.Source = $bmp
        } catch { }
    }

    # ---- Build Debloat checkboxes ----
    $script:FBCheckboxes = @{}

    # App Removal (from BloatwareApps, grouped)
    $bloatByCat = @{}
    foreach ($a in $script:BloatwareApps) {
        if (-not $bloatByCat.ContainsKey($a.Category)) { $bloatByCat[$a.Category] = @() }
        $bloatByCat[$a.Category] += $a
    }
    foreach ($cat in ($bloatByCat.Keys | Sort-Object)) {
        $lbl = New-Object System.Windows.Controls.TextBlock
        $lbl.Text = " $cat"
        $lbl.FontWeight = "Bold"
        $lbl.Foreground = $window.Resources["FgColor"]
        $lbl.Margin = "0,8,0,4"
        $appPanel.Children.Add($lbl) | Out-Null
        foreach ($a in $bloatByCat[$cat]) {
            $checked = $script:RecommendedRemovals -contains $a.Name
            $cb = Add-WPFCheckboxToPanel -window $window -panel $appPanel -Text $a.Label -FeatureId "APP_$($a.Name)" -Checked $checked
            $cb.Tag = $a.Name
            $script:FBCheckboxes["APP_$($a.Name)"] = $cb
        }
    }

    # Privacy
    $privacyFeatures = @(
        @{Id="DisableTelemetry"; Text="Disable Telemetry & Diagnostics"; Tip="Stops diagnostic data sending"},
        @{Id="DisableBingSearch"; Text="Disable Bing Search"; Tip="Removes Bing from Windows Search"},
        @{Id="DisableSuggestedNotifications"; Text="Disable Suggested Notifications"; Tip="Stops notification suggestions"},
        @{Id="DisableThirdPartyBgApps"; Text="Disable Third-party Background Apps"; Tip="Blocks background apps"},
        @{Id="DisableDeliveryOptimization"; Text="Disable Delivery Optimization (P2P)"; Tip="Stops P2P update sharing"},
        @{Id="DisableLockScreen"; Text="Disable Lock Screen"; Tip="Skips lock screen at boot"}
    )
    foreach ($f in $privacyFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $privacyPanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
    }

    # AI
    $aiFeatures = @(
        @{Id="DisableCopilot"; Text="Disable Microsoft Copilot"; Tip="Removes Copilot"},
        @{Id="DisableRecall"; Text="Disable Windows Recall"; Tip="Disables Recall feature"},
        @{Id="DisableWidgets"; Text="Disable Widgets"; Tip="Removes Widgets from taskbar"}
    )
    foreach ($f in $aiFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $aiPanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
    }

    # Interface
    $ifaceFeatures = @(
        @{Id="EnableDarkMode"; Text="Enable System Dark Mode"; Tip="Applies dark theme"},
        @{Id="EnableFileExtensions"; Text="Show File Extensions"; Tip="Shows file extensions in Explorer"},
        @{Id="EnableClassicContextMenu"; Text="Classic Context Menu (Win10)"; Tip="Restores Win10 context menu"}
    )
    foreach ($f in $ifaceFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $interfacePanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
    }

    # Gaming
    $cb = Add-WPFCheckboxToPanel -window $window -panel $gamingPanel -Text "Disable Xbox Game Bar & DVR" -FeatureId "DisableGameBar" -ToolTipText "Disables Game Bar recording"
    $script:FBCheckboxes["DisableGameBar"] = $cb

    # System
    $sysFeatures = @(
        @{Id="EnableEndTask"; Text="Enable End Task in Taskbar"; Tip="Adds End Task to taskbar right-click"},
        @{Id="DisableFastStartup"; Text="Disable Fast Startup"; Tip="Full shutdown on power off"}
    )
    foreach ($f in $sysFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $systemPanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
    }

    # ---- Build Install checkboxes ----
    $script:FBInstallChecks = @{}
    $panelMap = @{
        Essentials = $installEssPanel
        Utilities  = $installUtilPanel
        Gaming     = $installGamPanel
        DevTools   = $installDevPanel
        Creative   = $installCrePanel
    }
    foreach ($cat in @("Essentials","Utilities","Gaming","DevTools","Creative")) {
        $panel = $panelMap[$cat]
        foreach ($app in $script:AvailableApps[$cat]) {
            $cb = Add-WPFCheckboxToPanel -window $window -panel $panel -Text $app.Name -FeatureId "INST_$($app.Id)" -ToolTipText $app.Category
            $cb.Tag = $app.Id
            $script:FBInstallChecks[$app.Id] = $cb
        }
    }

    # ---- Build Tweaks checkboxes (mirrors Debloat for convenience) ----
    $tweaksMap = @{
        Privacy  = $tweaksPrivPanel
        System   = $tweaksSysPanel
        Explorer = $tweaksExpPanel
        AI       = $tweaksAIPanel
        Taskbar  = $tweaksTaskPanel
    }
    $script:FBTweakChecks = @{}
    $tweaksByCat = @(
        @{Cat="Privacy"; Items=@("DisableTelemetry","DisableBingSearch","DisableSuggestedNotifications","DisableThirdPartyBgApps","DisableDeliveryOptimization","DisableLockScreen")},
        @{Cat="System"; Items=@("EnableEndTask","DisableFastStartup")},
        @{Cat="Explorer"; Items=@("EnableDarkMode","EnableFileExtensions","EnableClassicContextMenu")},
        @{Cat="AI"; Items=@("DisableCopilot","DisableRecall","DisableWidgets")},
        @{Cat="Taskbar"; Items=@("EnableEndTask")}
    )
    foreach ($g in $tweaksByCat) {
        $panel = $tweaksMap[$g.Cat]
        foreach ($id in $g.Items) {
            $existing = $script:FBCheckboxes[$id]
            if ($existing) {
                # Clone checkbox content to tweaks panel
                $cb = Add-WPFCheckboxToPanel -window $window -panel $panel -Text $existing.Content -FeatureId "TWEAK_$id" -ToolTipText $($existing.ToolTip -as [System.Windows.Controls.TextBlock]).Text
                $cb.Tag = $id
                $script:FBTweakChecks["TWEAK_$id"] = $cb
            }
        }
    }

    # ---- Event: Theme Toggle ----
    $themeBtn.Add_Click({
        if ($script:currentTheme -eq "dark") { $script:currentTheme = "light"; $useDark = $false }
        else { $script:currentTheme = "dark"; $useDark = $true }
        Set-WPFWindowTheme -window $window -usesDarkMode $useDark

        # Reload logo
        $logoPath = if ($useDark -and (Test-Path $script:LogoDark)) { $script:LogoDark } elseif (Test-Path $script:LogoLight) { $script:LogoLight } else { $null }
        if ($logoPath) {
            try {
                $bmp = [System.Windows.Media.Imaging.BitmapImage]::new()
                $bmp.BeginInit(); $bmp.UriSource = [System.Uri]::new($logoPath, [System.UriKind]::Absolute); $bmp.EndInit()
                $logoImg.Source = $bmp
            } catch { }
        }
    })

    # ---- Event: Close ----
    $closeBtn.Add_Click({ $window.Close() })

    # ---- Event: Debloat Select All ----
    $debloatAll.Add_Click({
        foreach ($cb in $script:FBCheckboxes.Values) { $cb.IsChecked = $true }
    })

    # ---- Event: Debloat Recommended ----
    $debloatRec.Add_Click({
        foreach ($cb in $script:FBCheckboxes.Values) {
            $tag = $cb.Tag
            if ($tag -and $script:RecommendedRemovals -contains $tag) { $cb.IsChecked = $true }
            elseif ($tag -notlike "APP_*") {
                # Tweaks that are recommended by default
                $defaults = @("DisableTelemetry","DisableBingSearch","DisableCopilot","DisableRecall","DisableWidgets","DisableGameBar","EnableDarkMode","EnableFileExtensions","DisableSuggestedNotifications","DisableDeliveryOptimization","EnableEndTask")
                if ($defaults -contains $tag) { $cb.IsChecked = $true }
            }
        }
    })

    # ---- Event: Debloat Apply ----
    $debloatApply.Add_Click({
        $checkedApps = ($script:FBCheckboxes.GetEnumerator() | Where-Object { $_.Key -like "APP_*" -and $_.Value.IsChecked } | ForEach-Object { $_.Value.Tag })
        if ($checkedApps.Count -gt 0) {
            $title = "Confirm Debloat"
            $msg = "Se eliminaran $($checkedApps.Count) aplicaciones. Se recomienda crear un punto de restauracion primero.`n`nContinuar?"
            $result = [System.Windows.MessageBox]::Show($msg, $title, "YesNo", "Warning")
            if ($result -eq "Yes") {
                Set-WPFProgressBar -Visible $true
                Remove-BloatwareApps -AppNames $checkedApps
                Set-WPFProgressBar -Visible $false
                Save-FBRegistryBackups
            }
        }

        $tweaksToApply = @()
        $tweakMap = @{
            "DisableTelemetry" = { Disable-FBTelemetry }
            "DisableBingSearch" = { Disable-FBBingSearch }
            "DisableCopilot" = { Disable-FBCopilot }
            "DisableRecall" = { Disable-FBRecall }
            "DisableWidgets" = { Disable-FBWidgets }
            "DisableGameBar" = { Disable-FBGameBar }
            "EnableDarkMode" = { Enable-FBDarkMode }
            "EnableFileExtensions" = { Enable-FBFileExtensions }
            "EnableClassicContextMenu" = { Enable-FBClassicContextMenu }
            "DisableFastStartup" = { Disable-FBFastStartup }
            "DisableLockScreen" = { Disable-FBLockScreen }
            "EnableEndTask" = { Enable-FBEndTask }
            "DisableSuggestedNotifications" = { Disable-FBSuggestedNotifications }
            "DisableThirdPartyBgApps" = { Disable-FBThirdPartyBgApps }
            "DisableDeliveryOptimization" = { Disable-FBDeliveryOptimization }
        }
        foreach ($kv in $script:FBCheckboxes.GetEnumerator()) {
            if ($kv.Key -notlike "APP_*" -and $kv.Value.IsChecked -and $tweakMap.ContainsKey($kv.Key)) {
                $tweaksToApply += $tweakMap[$kv.Key]
            }
        }
        if ($tweaksToApply.Count -gt 0) {
            $title = "Confirm Tweaks"
            $msg = "Se aplicaran $($tweaksToApply.Count) cambios de registro.`n`nContinuar?"
            $result = [System.Windows.MessageBox]::Show($msg, $title, "YesNo", "Warning")
            if ($result -eq "Yes") {
                Set-WPFProgressBar -Visible $true
                foreach ($t in $tweaksToApply) { & $t }
                Set-WPFProgressBar -Visible $false
                Save-FBRegistryBackups
            }
        }
    })

    # ---- Event: Install Apply ----
    $installApply.Add_Click({
        $selected = ($script:FBInstallChecks.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key })
        if ($selected.Count -eq 0) { return }
        $msg = "Se instalaran $($selected.Count) aplicaciones. Este proceso puede tardar varios minutos.`n`nContinuar?"
        $result = [System.Windows.MessageBox]::Show($msg, "Confirmar Instalacion", "YesNo", "Question")
        if ($result -eq "Yes") {
            Set-WPFProgressBar -Visible $true
            Install-FBApps -AppIds $selected
            Set-WPFProgressBar -Visible $false
        }
    })

    # ---- Event: Update All ----
    $installUpdateAll.Add_Click({
        $result = [System.Windows.MessageBox]::Show("Actualizar TODAS las aplicaciones instaladas?", "Confirmar", "YesNo", "Question")
        if ($result -eq "Yes") {
            Set-WPFProgressBar -Visible $true
            Update-FBAllApps
            Set-WPFProgressBar -Visible $false
        }
    })

    # ---- Event: Tweaks Apply ----
    $tweaksApply.Add_Click({
        $tweakMap = @{
            "TWEAK_DisableTelemetry" = { Disable-FBTelemetry }
            "TWEAK_DisableBingSearch" = { Disable-FBBingSearch }
            "TWEAK_DisableCopilot" = { Disable-FBCopilot }
            "TWEAK_DisableRecall" = { Disable-FBRecall }
            "TWEAK_DisableWidgets" = { Disable-FBWidgets }
            "TWEAK_EnableDarkMode" = { Enable-FBDarkMode }
            "TWEAK_EnableFileExtensions" = { Enable-FBFileExtensions }
            "TWEAK_EnableClassicContextMenu" = { Enable-FBClassicContextMenu }
            "TWEAK_DisableFastStartup" = { Disable-FBFastStartup }
            "TWEAK_EnableEndTask" = { Enable-FBEndTask }
            "TWEAK_DisableSuggestedNotifications" = { Disable-FBSuggestedNotifications }
            "TWEAK_DisableThirdPartyBgApps" = { Disable-FBThirdPartyBgApps }
            "TWEAK_DisableDeliveryOptimization" = { Disable-FBDeliveryOptimization }
            "TWEAK_DisableLockScreen" = { Disable-FBLockScreen }
            "TWEAK_DisableGameBar" = { Disable-FBGameBar }
        }
        $toApply = @()
        foreach ($kv in $script:FBTweakChecks.GetEnumerator()) {
            if ($kv.Value.IsChecked -and $tweakMap.ContainsKey($kv.Key)) { $toApply += $tweakMap[$kv.Key] }
        }
        if ($toApply.Count -eq 0) { return }
        $msg = "Se aplicaran $($toApply.Count) tweaks.`n`nContinuar?"
        $result = [System.Windows.MessageBox]::Show($msg, "Confirmar Tweaks", "YesNo", "Warning")
        if ($result -eq "Yes") {
            Set-WPFProgressBar -Visible $true
            foreach ($t in $toApply) { & $t }
            Set-WPFProgressBar -Visible $false
            Save-FBRegistryBackups
        }
    })

    # ---- Tool buttons ----
    $toolRepairWU.Add_Click({
        $r = [System.Windows.MessageBox]::Show("Reparar Windows Update? Esto reseteara el catalogo.", "Confirmar", "YesNo", "Warning")
        if ($r -eq "Yes") { Set-WPFProgressBar -Visible $true; Repair-FBWindowsUpdate; Set-WPFProgressBar -Visible $false }
    })
    $toolSFC.Add_Click({
        $r = [System.Windows.MessageBox]::Show("Ejecutar SFC y DISM? Puede tardar 15-30 min.", "Confirmar", "YesNo", "Warning")
        if ($r -eq "Yes") { Set-WPFProgressBar -Visible $true; Run-FBSFCAndDISM; Set-WPFProgressBar -Visible $false }
    })
    $toolCleanTemp.Add_Click({ Clear-FBTemporaryFiles })
    $toolRestorePt.Add_Click({ Create-FBRestorePoint })
    $toolMicroWin.Add_Click({ Invoke-FBMicroWin })

    # ---- Show Window ----
    $window.ShowDialog() | Out-Null
}

function Get-FBSystemUsesDarkMode {
    try {
        $val = Get-ItemPropertyValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" -ErrorAction Stop
        return ($val -eq 0)
    } catch { return $true }
}
