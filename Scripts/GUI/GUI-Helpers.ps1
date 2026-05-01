function Set-WPFWindowTheme {
    param($window, [bool]$usesDarkMode)
    $dict = $window.Resources.MergedDictionaries[0]
    $d = @{}
    if ($usesDarkMode) {
        $d.BgColor           = "#1E1E1E"
        $d.FgColor           = "#FFFFFF"
        $d.BorderColor       = "#3E3E3E"
        $d.ButtonBg          = "#0078D7"
        $d.ButtonHover       = "#1A8CD8"
        $d.ButtonPressed     = "#006CBE"
        $d.ButtonDisabled    = "#444444"
        $d.ButtonTextDisabled = "#888888"
        $d.SecondaryButtonBg = "#2D2D2D"
        $d.SecondaryButtonHover = "#3D3D3D"
        $d.SecondaryButtonPressed = "#252525"
        $d.SecondaryButtonDisabled = "#2D2D2D"
        $d.SecondaryButtonTextDisabled = "#666666"
        $d.ButtonBorderColor = "#555555"
        $d.CardBgColor       = "#252525"
        $d.CheckBoxBgColor   = "#2D2D2D"
        $d.CheckBoxBorderColor = "#555555"
        $d.CheckBoxHoverColor = "#3D3D3D"
        $d.ScrollBarThumbColor = "#555555"
        $d.ScrollBarThumbHoverColor = "#777777"
        $d.CloseHover        = "#C42B1C"
        $d.TitlebarButtonHover = "#333333"
        $d.TitlebarButtonPressed = "#222222"
    } else {
        $d.BgColor           = "#F3F3F3"
        $d.FgColor           = "#1A1A1A"
        $d.BorderColor       = "#CCCCCC"
        $d.ButtonBg          = "#0078D7"
        $d.ButtonHover       = "#1A8CD8"
        $d.ButtonPressed     = "#006CBE"
        $d.ButtonDisabled    = "#C8C8C8"
        $d.ButtonTextDisabled = "#999999"
        $d.SecondaryButtonBg = "#FFFFFF"
        $d.SecondaryButtonHover = "#F5F5F5"
        $d.SecondaryButtonPressed = "#EEEEEE"
        $d.SecondaryButtonDisabled = "#F0F0F0"
        $d.SecondaryButtonTextDisabled = "#AAAAAA"
        $d.ButtonBorderColor = "#CCCCCC"
        $d.CardBgColor       = "#FFFFFF"
        $d.CheckBoxBgColor   = "#FFFFFF"
        $d.CheckBoxBorderColor = "#999999"
        $d.CheckBoxHoverColor = "#F0F0F0"
        $d.ScrollBarThumbColor = "#C1C1C1"
        $d.ScrollBarThumbHoverColor = "#A1A1A1"
        $d.CloseHover        = "#C42B1C"
        $d.TitlebarButtonHover = "#E5E5E5"
        $d.TitlebarButtonPressed = "#D6D6D6"
    }
    foreach ($k in $d.Keys) {
        $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($d[$k])
        $brush.Freeze()
        $dict[$k] = $brush
    }
}

function Add-WPFCheckboxToPanel {
    param($window, $panel, [string]$Text, [string]$FeatureId, [bool]$Checked = $false, [string]$ToolTipText = "")
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $Text
    $safeName = "FBCB_$($FeatureId -replace '[^a-zA-Z0-9_]', '_')"
    if ($window.Resources.Contains("FeatureCheckboxStyle")) {
        $cb.Style = $window.Resources["FeatureCheckboxStyle"]
    }
    $cb.IsChecked = $Checked
    $cb.Name = $safeName
    $cb.SetValue([System.Windows.Automation.AutomationProperties]::NameProperty, $Text)
    if ($ToolTipText) {
        $cb.ToolTip = $ToolTipText
    }
    $panel.Children.Add($cb) | Out-Null
    try { $window.RegisterName($cb.Name, $cb) } catch { }
    return $cb
}

function Set-WPFProgressBar {
    param([bool]$Visible, [double]$Value = -1)
    if ($null -eq $script:MainProgressBar) { return }
    $script:MainProgressBar.Dispatcher.Invoke([action]{
        $script:MainProgressBar.Visibility = if ($Visible) { "Visible" } else { "Hidden" }
        if ($Value -ge 0) {
            $script:MainProgressBar.IsIndeterminate = $false
            $script:MainProgressBar.Value = [Math]::Min(100, [Math]::Max(0, $Value))
        } else {
            $script:MainProgressBar.IsIndeterminate = $Visible
        }
    })
}
