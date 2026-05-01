function Show-FBMainWindow {
    Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase | Out-Null

    $usesDark = Get-FBSystemUsesDarkMode

    # Load XAML from temp folder (resolves relative SharedStyles reference)
    $tempDir = Join-Path $env:TEMP "FENBloat_$(Get-Random)"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    $tempMain = Join-Path $tempDir "FENBloat_MainWindow.xaml"
    $tempShared = Join-Path $tempDir "SharedStyles.xaml"
    
    Copy-Item -Path $script:SharedStylesSchema -Destination $tempShared -Force
    
    $xaml = Get-Content -Path $script:MainWindowSchema -Raw
    [System.IO.File]::WriteAllText($tempMain, $xaml, [System.Text.Encoding]::UTF8)
    
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

    # Get Controls
    $themeBtn         = $window.FindName("ThemeToggleBtn")
    $closeBtn         = $window.FindName("CloseBtn")
    $logoImg          = $window.FindName("LogoImage")
    $mainProgress     = $window.FindName("MainProgressBar")
    $script:MainProgressBar = $mainProgress

    # Install Panels
    $installEssPanel  = $window.FindName("InstallEssentialsPanel")
    $installUtilPanel = $window.FindName("InstallUtilitiesPanel")
    $installGamPanel  = $window.FindName("InstallGamingPanel")
    $installDevPanel  = $window.FindName("InstallDevPanel")
    $installCrePanel  = $window.FindName("InstallCreativePanel")
    $installSocPanel  = $window.FindName("InstallSocialPanel")
    $installMsPanel   = $window.FindName("InstallMicrosoftPanel")
    $installProdPanel = $window.FindName("InstallProductivityPanel")
    $installGamesPanel = $window.FindName("InstallGamesPanel")

    # Tweaks Panels
    $privacyAIPanel   = $window.FindName("PrivacyAIPanel")
    $systemUIPanel    = $window.FindName("SystemUIPanel")
    $notifTaskbarPanel = $window.FindName("NotifTaskbarPanel")

    # Tweaks Buttons
    $tweaksRecommended = $window.FindName("TweaksRecommendedBtn")
    $tweaksSelectAll   = $window.FindName("TweaksSelectAllBtn")
    $tweaksUnselectAll = $window.FindName("TweaksUnselectAllBtn")
    $tweaksApply       = $window.FindName("TweaksApplyBtn")
    $tweaksStatus      = $window.FindName("TweaksStatusText")

    # Install Buttons
    $installUnselectAll  = $window.FindName("InstallUnselectAllBtn")
    $installRemove       = $window.FindName("InstallRemoveBtn")
    $installUpgrade      = $window.FindName("InstallUpgradeBtn")
    $uninstallApps       = $window.FindName("UninstallAppsBtn")
    $installUpdateAll    = $window.FindName("InstallUpdateAllBtn")
    $installStatus       = $window.FindName("InstallStatusText")

    # Tools Buttons
    $toolRepairWU     = $window.FindName("ToolRepairWU")
    $toolSFC          = $window.FindName("ToolSFC")
    $toolCleanTemp    = $window.FindName("ToolCleanTemp")
    $toolRestorePt    = $window.FindName("ToolRestorePoint")
    $toolMicroWin     = $window.FindName("ToolMicroWin")
    $toolOpenLogs     = $window.FindName("ToolOpenLogs")

    # Load Logo
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

    # ==============================================================================
    # BUILD TWEAKS CHECKBOXES
    # ==============================================================================
    $script:FBCheckboxes = @{}
    $script:FBPrivacyChecks = @{}
    $script:FBSystemChecks = @{}
    $script:FBNotifChecks = @{}

    $updateTweaksStatus = {
        $count = ($script:FBCheckboxes.Values | Where-Object { $_.IsChecked }).Count
        $tweaksStatus.Text = if ($count -gt 0) { "$count selected" } else { "All cleared" }
    }

    # 1. Privacy & AI
    $privacyFeatures = @(
        @{Id="DisableTelemetry"; Text="Disable Telemetry & Diagnostics"; Tip="Stops diagnostic data sending"},
        @{Id="DisableBingSearch"; Text="Disable Bing Search"; Tip="Removes Bing from Windows Search"},
        @{Id="DisableCopilot"; Text="Disable Microsoft Copilot"; Tip="Removes Copilot"},
        @{Id="DisableRecall"; Text="Disable Windows Recall"; Tip="Disables Recall feature"},
        @{Id="DisableWidgets"; Text="Disable Widgets"; Tip="Removes Widgets from taskbar"}
    )
    foreach ($f in $privacyFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $privacyAIPanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
        $script:FBPrivacyChecks[$f.Id] = $cb
        $cb.add_Checked({ & $updateTweaksStatus })
        $cb.add_Unchecked({ & $updateTweaksStatus })
    }

    # 2. System & UI
    $systemFeatures = @(
        @{Id="EnableDarkMode"; Text="Enable System Dark Mode"; Tip="Applies dark theme"},
        @{Id="EnableFileExtensions"; Text="Show File Extensions"; Tip="Shows file extensions in Explorer"},
        @{Id="EnableClassicContextMenu"; Text="Classic Context Menu (Win10)"; Tip="Restores Win10 context menu"},
        @{Id="DisableGameBar"; Text="Disable Xbox Game Bar & DVR"; Tip="Disables Game Bar recording"},
        @{Id="EnableEndTask"; Text="Enable End Task in Taskbar"; Tip="Adds End Task to taskbar right-click"},
        @{Id="DisableFastStartup"; Text="Disable Fast Startup"; Tip="Full shutdown on power off"}
    )
    foreach ($f in $systemFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $systemUIPanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
        $script:FBSystemChecks[$f.Id] = $cb
        $cb.add_Checked({ & $updateTweaksStatus })
        $cb.add_Unchecked({ & $updateTweaksStatus })
    }

    # 3. Notifications & Taskbar
    $notifFeatures = @(
        @{Id="DisableSuggestedNotifications"; Text="Disable Suggested Notifications"; Tip="Stops notification suggestions"},
        @{Id="DisableThirdPartyBgApps"; Text="Disable Third-party Background Apps"; Tip="Blocks background apps"},
        @{Id="DisableDeliveryOptimization"; Text="Disable Delivery Optimization (P2P)"; Tip="Stops P2P update sharing"},
        @{Id="DisableLockScreen"; Text="Disable Lock Screen"; Tip="Skips lock screen at boot"}
    )
    foreach ($f in $notifFeatures) {
        $cb = Add-WPFCheckboxToPanel -window $window -panel $notifTaskbarPanel -Text $f.Text -FeatureId $f.Id -ToolTipText $f.Tip
        $script:FBCheckboxes[$f.Id] = $cb
        $script:FBNotifChecks[$f.Id] = $cb
        $cb.add_Checked({ & $updateTweaksStatus })
        $cb.add_Unchecked({ & $updateTweaksStatus })
    }

    # ==============================================================================
    # BUILD INSTALL CHECKBOXES
    # ==============================================================================
    $script:FBInstallChecks = @{}
    $panelMap = @{
        Essentials = $installEssPanel
        Utilities  = $installUtilPanel
        Gaming     = $installGamPanel
        DevTools   = $installDevPanel
        Creative   = $installCrePanel
        Social     = $installSocPanel
    }

    $updateInstallStatus = {
        $count = ($script:FBInstallChecks.Values + $script:FBBloatwareChecks.Values | Where-Object { $_.IsChecked }).Count
        $installStatus.Text = if ($count -gt 0) { "$count selected" } else { "All cleared" }
    }

    foreach ($cat in @("Essentials","Utilities","Gaming","DevTools","Creative","Social")) {
        $panel = $panelMap[$cat]
        if (-not $panel) { continue }
        if ($script:AvailableApps.ContainsKey($cat)) {
            foreach ($app in $script:AvailableApps[$cat]) {
                $cb = New-Object System.Windows.Controls.CheckBox
                $sp = New-Object System.Windows.Controls.StackPanel
                $sp.Orientation = "Horizontal"
                $tbName = New-Object System.Windows.Controls.TextBlock
                $tbName.Text = $app.Name
                $tbName.VerticalAlignment = "Center"
                $tbLatest = New-Object System.Windows.Controls.TextBlock
                $tbLatest.Text = " (Latest)"
                $tbLatest.VerticalAlignment = "Center"
                $tbLatest.Opacity = 0.5
                $tbSep = New-Object System.Windows.Controls.TextBlock
                $tbSep.Text = " "
                $tbSep.VerticalAlignment = "Center"
                $tbLink = New-Object System.Windows.Controls.TextBlock
                $tbLink.Text = ">>"
                $tbLink.VerticalAlignment = "Center"
                $tbLink.Cursor = [System.Windows.Input.Cursors]::Hand
                if ($app.VersionUrl -and $app.VersionUrl -ne "") {
                    $tbLink.ToolTip = $app.VersionUrl
                    $tbLink.FontFamily = "Segoe UI"
                    $tbLink.FontWeight = "Bold"
                    $tbLink.Add_PreviewMouseLeftButtonDown([scriptblock]::Create("param(`$s,`$e); Start-Process '$($app.VersionUrl)'; `$e.Handled = `$true"))
                } else {
                    $tbLink.Visibility = "Collapsed"
                }
                $tbLink.Add_MouseEnter({
                    param($s,$e)
                    $s.Opacity = 1
                })
                $tbLink.Add_MouseLeave({
                    param($s,$e)
                    $s.Opacity = 0.7
                })
                $tbLink.Opacity = 0.7
                $sp.Children.Add($tbName) | Out-Null
                $sp.Children.Add($tbLatest) | Out-Null
                $sp.Children.Add($tbSep) | Out-Null
                $sp.Children.Add($tbLink) | Out-Null
                $cb.Content = $sp
                $safeName = "FBCB_INST_$($app.Id -replace '[^a-zA-Z0-9_]', '_')"
                $cb.IsChecked = $false
                $cb.Name = $safeName
                $cb.Tag = $app.Id
                if ($window.Resources.Contains("FeatureCheckboxStyle")) {
                    $cb.Style = $window.Resources["FeatureCheckboxStyle"]
                }
                $panel.Children.Add($cb) | Out-Null
                try { $window.RegisterName($cb.Name, $cb) } catch { }
                $script:FBInstallChecks[$app.Id] = $cb
                $cb.add_Checked({ & $updateInstallStatus })
                $cb.add_Unchecked({ & $updateInstallStatus })
            }
        }
    }

    # ==============================================================================
    # BUILD BLOATWARE CHECKBOXES (App Removal) - distributed into categories
    # ==============================================================================
    $script:FBBloatwareChecks = @{}

    $bloatRemap = @{
        # Gaming & Xbox
        "Microsoft.XboxApp"                    = @{ Panel=$installGamPanel; Label="Xbox Console Companion (Microsoft)" }
        "Microsoft.XboxGameOverlay"            = @{ Panel=$installGamPanel; Label="Xbox Game Overlay (Microsoft)" }
        "Microsoft.XboxGamingOverlay"          = @{ Panel=$installGamPanel; Label="Xbox Game Bar (Microsoft)" }
        "Microsoft.XboxIdentityProvider"       = @{ Panel=$installGamPanel; Label="Xbox Identity Provider (Microsoft)" }
        "Microsoft.XboxSpeechToTextOverlay"    = @{ Panel=$installGamPanel; Label="Xbox Speech To Text (Microsoft)" }
        "Microsoft.Xbox.TCUI"                  = @{ Panel=$installGamPanel; Label="Xbox TCUI (Microsoft)" }
        "Microsoft.GamingApp"                  = @{ Panel=$installGamPanel; Label="Xbox App (Microsoft)" }

        # Games
        "Microsoft.MicrosoftSolitaireCollection" = @{ Panel=$installGamesPanel; Label="Solitaire Collection (Microsoft)" }
        "king.com.CandyCrushSaga"              = @{ Panel=$installGamesPanel; Label="Candy Crush Saga" }
        "king.com.CandyCrushSodaSaga"          = @{ Panel=$installGamesPanel; Label="Candy Crush Soda" }

        # Social & Communication
        "Microsoft.SkypeApp"                   = @{ Panel=$installSocPanel; Label="Skype (Microsoft)" }
        "Microsoft.People"                     = @{ Panel=$installSocPanel; Label="People (Microsoft)" }

        # Utilities
        "Microsoft.WindowsAlarms"              = @{ Panel=$installUtilPanel; Label="Alarms & Clock (Microsoft)" }
        "Microsoft.WindowsCamera"              = @{ Panel=$installUtilPanel; Label="Camera (Microsoft)" }
        "Microsoft.WindowsMaps"                = @{ Panel=$installUtilPanel; Label="Maps (Microsoft)" }
        "Microsoft.WindowsSoundRecorder"       = @{ Panel=$installUtilPanel; Label="Sound Recorder (Microsoft)" }
        "Microsoft.MSPaint"                    = @{ Panel=$installUtilPanel; Label="Paint 3D (Microsoft)" }
        "Microsoft.Print3D"                    = @{ Panel=$installUtilPanel; Label="Print 3D (Microsoft)" }

        # Creative & Media
        "Microsoft.ZuneMusic"                  = @{ Panel=$installCrePanel; Label="Groove Music (Microsoft)" }
        "Microsoft.ZuneVideo"                  = @{ Panel=$installCrePanel; Label="Movies & TV (Microsoft)" }
        "Clipchamp.Clipchamp"                  = @{ Panel=$installCrePanel; Label="Clipchamp (Microsoft)" }

        # Microsoft Apps
        "Microsoft.BingWeather"                = @{ Panel=$installMsPanel; Label="Bing Weather (Microsoft)" }
        "Microsoft.BingNews"                   = @{ Panel=$installMsPanel; Label="Bing News (Microsoft)" }
        "Microsoft.BingSearch"                 = @{ Panel=$installMsPanel; Label="Bing Search (Microsoft)" }
        "Microsoft.GetHelp"                    = @{ Panel=$installMsPanel; Label="Get Help (Microsoft)" }
        "Microsoft.Getstarted"                 = @{ Panel=$installMsPanel; Label="Get Started (Microsoft)" }
        "Microsoft.YourPhone"                  = @{ Panel=$installMsPanel; Label="Phone Link (Microsoft)" }
        "Microsoft.549981C3F5F10"              = @{ Panel=$installMsPanel; Label="Cortana (Microsoft)" }
        "MicrosoftWindows.Client.WebExperience" = @{ Panel=$installMsPanel; Label="Widgets (Microsoft)" }
        "MicrosoftCorporationII.MicrosoftFamily" = @{ Panel=$installMsPanel; Label="Microsoft Family (Microsoft)" }
        "Microsoft.WindowsFeedbackHub"         = @{ Panel=$installMsPanel; Label="Feedback Hub (Microsoft)" }

        # Productivity & Cloud
        "Microsoft.Office.OneNote"             = @{ Panel=$installProdPanel; Label="OneNote (Microsoft)" }
        "Microsoft.MicrosoftStickyNotes"       = @{ Panel=$installProdPanel; Label="Sticky Notes (Microsoft)" }
        "Microsoft.Todos"                      = @{ Panel=$installProdPanel; Label="To Do (Microsoft)" }
        "Microsoft.MicrosoftOfficeHub"         = @{ Panel=$installProdPanel; Label="Office Hub (Microsoft)" }
        "Microsoft.PowerAutomateDesktop"       = @{ Panel=$installProdPanel; Label="Power Automate (Microsoft)" }
        "Microsoft.OneDrive"                   = @{ Panel=$installProdPanel; Label="OneDrive (Microsoft)" }
    }

    foreach ($a in $script:BloatwareApps) {
        if (-not $bloatRemap.ContainsKey($a.Name)) { continue }
        $info = $bloatRemap[$a.Name]
        $checked = $script:RecommendedRemovals -contains $a.Name
        $cb = Add-WPFCheckboxToPanel -window $window -panel $info.Panel -Text $info.Label -FeatureId "BLT_$($a.Name)" -Checked $checked
        $cb.Tag = $a.Name
        $script:FBBloatwareChecks[$a.Name] = $cb
        $cb.add_Checked({ & $updateInstallStatus })
        $cb.add_Unchecked({ & $updateInstallStatus })
    }

    # ==============================================================================
    # EVENT HANDLERS
    # ==============================================================================

    # ---- Theme Toggle ----
    $themeBtn.Add_Click({
        if ($script:currentTheme -eq "dark") { $script:currentTheme = "light"; $useDark = $false }
        else { $script:currentTheme = "dark"; $useDark = $true }
        Set-WPFWindowTheme -window $window -usesDarkMode $useDark
        $logoPath = if ($useDark -and (Test-Path $script:LogoDark)) { $script:LogoDark } elseif (Test-Path $script:LogoLight) { $script:LogoLight } else { $null }
        if ($logoPath) {
            try {
                $bmp = [System.Windows.Media.Imaging.BitmapImage]::new()
                $bmp.BeginInit(); $bmp.UriSource = [System.Uri]::new($logoPath, [System.UriKind]::Absolute); $bmp.EndInit()
                $logoImg.Source = $bmp
            } catch { }
        }
    })

    # ---- Close ----
    $closeBtn.Add_Click({ $window.Close() })

    # ================== TWEAKS EVENTS ==================

    # ---- Recommended ----
    $tweaksRecommended.Add_Click({
        foreach ($cb in $script:FBCheckboxes.Values) { $cb.IsChecked = $false }
        $defaults = @(
            "DisableTelemetry","DisableBingSearch","DisableCopilot","DisableRecall","DisableWidgets",
            "DisableGameBar","EnableFileExtensions","DisableSuggestedNotifications","DisableDeliveryOptimization"
        )
        foreach ($id in $defaults) {
            if ($script:FBCheckboxes.ContainsKey($id)) { $script:FBCheckboxes[$id].IsChecked = $true }
        }
        & $updateTweaksStatus
    })

    # ---- Select All ----
    $tweaksSelectAll.Add_Click({
        foreach ($cb in $script:FBCheckboxes.Values) { $cb.IsChecked = $true }
        & $updateTweaksStatus
    })

    # ---- Unselect All ----
    $tweaksUnselectAll.Add_Click({
        foreach ($cb in $script:FBCheckboxes.Values) { $cb.IsChecked = $false }
        & $updateTweaksStatus
    })

    # ---- Apply Tweaks ----
    $tweaksApply.Add_Click({
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
            if ($kv.Value.IsChecked -and $tweakMap.ContainsKey($kv.Key)) {
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
        $tweaksStatus.Text = "$($tweaksToApply.Count) tweaks applied"
    })

    # ================== INSTALL EVENTS ==================

    # ---- Unselect All (Install tab) ----
    $installUnselectAll.Add_Click({
        foreach ($cb in $script:FBInstallChecks.Values) { $cb.IsChecked = $false }
        foreach ($cb in $script:FBBloatwareChecks.Values) { $cb.IsChecked = $false }
        & $updateInstallStatus
    })

    # ---- Remove Needless Apps (Recommended) ----
    $script:_removeBusy = $false
    $installRemove.Add_Click({
        if ($script:_removeBusy) { return }
        $script:_removeBusy = $true

        foreach ($kv in $script:FBBloatwareChecks.GetEnumerator()) { $kv.Value.IsChecked = $false }
        foreach ($a in $script:BloatwareApps) {
            if ($script:RecommendedRemovals -contains $a.Name -and $script:FBBloatwareChecks.ContainsKey($a.Name)) {
                $script:FBBloatwareChecks[$a.Name].IsChecked = $true
            }
        }

        $toRemove = @()
        foreach ($kv in $script:FBBloatwareChecks.GetEnumerator()) {
            if ($kv.Value.IsChecked) { $toRemove += $kv.Key }
        }

        if ($toRemove.Count -gt 0) {
            $list = ($toRemove | ForEach-Object { "  - $_" }) -join "`n"
            $msg = "The following $($toRemove.Count) apps will be removed:`n`n$list`n`nContinue?"
            $result = [System.Windows.MessageBox]::Show($msg, "Remove Needless Apps", "YesNo", "Warning")
            if ($result -eq "Yes") {
                $installStatus.Text = "Removing $($toRemove.Count) apps..."
                Set-WPFProgressBar -Visible $true
                $errors = @()
                foreach ($name in $toRemove) {
                    try {
                        $res = Remove-FBAppxPackage -PackageName $name -AllUsers
                        if (-not $res.Success) { $errors += $name }
                    } catch { $errors += "$name ($($_.Exception.Message))" }
                }
                Set-WPFProgressBar -Visible $false
                foreach ($name in $toRemove) {
                    if ($script:FBBloatwareChecks.ContainsKey($name)) { $script:FBBloatwareChecks[$name].IsChecked = $false }
                }
                & $updateInstallStatus
                if ($errors.Count -gt 0) {
                    $installStatus.Text = "$($toRemove.Count - $errors.Count)/$($toRemove.Count) removed. $($errors.Count) failed."
                }
            }
        }
        $script:_removeBusy = $false
    })

    # ---- Install / Upgrade Apps ----
    $installUpgrade.Add_Click({
        $selected = @($script:FBInstallChecks.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key })
        if ($selected.Count -eq 0) { return }
        $msg = "Se instalaran/actualizaran $($selected.Count) aplicaciones.`n`nContinuar?"
        $result = [System.Windows.MessageBox]::Show($msg, "Confirmar Instalacion", "YesNo", "Question")
        if ($result -eq "Yes") {
            Set-WPFProgressBar -Visible $true
            Install-FBApps -AppIds $selected
            Set-WPFProgressBar -Visible $false
        }
    })

    # ---- Uninstall Apps ----
    $uninstallApps.Add_Click({
        $selectedBloat = @()
        foreach ($kv in $script:FBBloatwareChecks.GetEnumerator()) {
            if ($kv.Value.IsChecked) { $selectedBloat += $kv.Key }
        }
        $selectedInstall = @()
        foreach ($kv in $script:FBInstallChecks.GetEnumerator()) {
            if ($kv.Value.IsChecked) { $selectedInstall += $kv.Key }
        }
        $total = $selectedBloat.Count + $selectedInstall.Count
        if ($total -eq 0) {
            $null = [System.Windows.MessageBox]::Show("No apps selected for uninstall.", "Uninstall", "OK", "Information")
            return
        }
        $parts = @()
        if ($selectedBloat.Count -gt 0) { $parts += "$($selectedBloat.Count) bloatware" }
        if ($selectedInstall.Count -gt 0) { $parts += "$($selectedInstall.Count) installed apps" }
        $msg = "Se eliminarian $($total) aplicaciones ($(($parts -join ', '))).`n`nContinuar?"
        $result = [System.Windows.MessageBox]::Show($msg, "Confirmar Desinstalacion", "YesNo", "Warning")
        if ($result -eq "Yes") {
            $installStatus.Text = "Uninstalling $total apps..."
            Set-WPFProgressBar -Visible $true
            $okCount = 0
            foreach ($name in $selectedBloat) {
                try {
                    $res = Remove-FBAppxPackage -PackageName $name -AllUsers
                    if ($res.Success) { $okCount++ }
                } catch { }
                if ($script:FBBloatwareChecks.ContainsKey($name)) { $script:FBBloatwareChecks[$name].IsChecked = $false }
            }
            foreach ($id in $selectedInstall) {
                try {
                    Write-Host "Uninstalling $id..."
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = "winget"
                    $psi.Arguments = "uninstall --id `"$id`" --silent --force"
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
                    if ($proc.ExitCode -eq 0) { $okCount++; Write-Host "  -> $id uninstalled successfully" }
                    else { Write-Host "  -> $id uninstall failed (exit code: $($proc.ExitCode))" }
                } catch { Write-Host "  -> Error uninstalling $id : $_" }
                if ($script:FBInstallChecks.ContainsKey($id)) { $script:FBInstallChecks[$id].IsChecked = $false }
            }
            Set-WPFProgressBar -Visible $false
            $installStatus.Text = "$okCount/$total apps uninstalled"
            & $updateInstallStatus
        }
    })

    # ---- Upgrade All ----
    $installUpdateAll.Add_Click({
        $result = [System.Windows.MessageBox]::Show("Actualizar TODAS las aplicaciones instaladas?", "Confirmar", "YesNo", "Question")
        if ($result -eq "Yes") {
            Set-WPFProgressBar -Visible $true
            Update-FBAllApps
            Set-WPFProgressBar -Visible $false
        }
    })

    # ================== TOOLS EVENTS ==================

    $toolRepairWU.Add_Click({
        $r = [System.Windows.MessageBox]::Show("Reparar Windows Update?", "Confirmar", "YesNo", "Warning")
        if ($r -eq "Yes") { Set-WPFProgressBar -Visible $true; Repair-FBWindowsUpdate; Set-WPFProgressBar -Visible $false }
    })
    $toolSFC.Add_Click({
        $r = [System.Windows.MessageBox]::Show("Ejecutar SFC y DISM?", "Confirmar", "YesNo", "Warning")
        if ($r -eq "Yes") { Set-WPFProgressBar -Visible $true; Run-FBSFCAndDISM; Set-WPFProgressBar -Visible $false }
    })
    $toolCleanTemp.Add_Click({ Clear-FBTemporaryFiles })
    $toolRestorePt.Add_Click({ Create-FBRestorePoint })
    $toolMicroWin.Add_Click({ Invoke-FBMicroWin })
    $toolOpenLogs.Add_Click({
        $logDir = Join-Path $PSScriptRoot "..\..\Logs"
        if (Test-Path $logDir) { Start-Process explorer.exe $logDir }
    })

    # ---- Show Window ----
    $window.ShowDialog() | Out-Null
}

function Get-FBSystemUsesDarkMode {
    try {
        $val = Get-ItemPropertyValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" -ErrorAction Stop
        return ($val -eq 0)
    } catch { return $true }
}
