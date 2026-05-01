<#
.SYNOPSIS
    Compile script para FEN-Bloat
.DESCRIPTION
    Compila los modulos individuales en un solo script FEN-Bloat.ps1.
    Tambien valida la sintaxis de PowerShell y genera estadisticas.
.NOTES
    Uso: .\compile.ps1
#>

[CmdletBinding()]
param(
    [switch]$Validate,
    [switch]$Stats,
    [string]$OutputPath = ".\FEN-Bloat.ps1"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FEN-Bloat - Compile Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$buildStart = Get-Date

# --- Configuration ---
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mainScript  = Join-Path $projectRoot "FEN-Bloat.ps1"

# --- Phase 1: Validate ---
if ($Validate -or -not $Stats) {
    Write-Host "[1/3] Validando sintaxis de PowerShell..." -ForegroundColor Yellow

    $errors = $null
    $tokens = $null
    $content = Get-Content -Path $mainScript -Raw -Encoding UTF8

    try {
        [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
    } catch {
        Write-Host "  ERROR: No se pudo analizar el script: $_" -ForegroundColor Red
        exit 1
    }

    if ($errors.Count -gt 0) {
        Write-Host "  ERRORES DE SINTAXIS ENCONTRADOS:" -ForegroundColor Red
        foreach ($err in $errors) {
            Write-Host "    Linea $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
        }
        exit 1
    } else {
        Write-Host "  SIN ERRORES DE SINTAXIS" -ForegroundColor Green
    }
}

# --- Phase 2: Stats ---
if ($Stats -or -not $Validate) {
    Write-Host ""
    Write-Host "[2/3] Generando estadisticas..." -ForegroundColor Yellow

    $content = Get-Content -Path $mainScript -Raw -Encoding UTF8
    $lines   = $content -split "`n"

    $totalLines = $lines.Count
    $codeLines  = ($lines | Where-Object { $_.Trim() -and $_.Trim() -notmatch '^\s*#' -and $_.Trim() -notmatch '^\s*$' }).Count
    $commentLines = ($lines | Where-Object { $_.Trim() -match '^\s*#' }).Count
    $blankLines   = ($lines | Where-Object { $_.Trim() -eq '' }).Count
    $fileSize     = [math]::Round((Get-Item $mainScript).Length / 1KB, 1)

    # Count functions
    $functionCount = ([regex]::Matches($content, 'function\s+\w+')).Count

    # Count regions
    $regionCount = ([regex]::Matches($content, '#region|# REGION')).Count

    Write-Host "  Archivo:       $mainScript" -ForegroundColor Gray
    Write-Host "  Tamano:        $fileSize KB" -ForegroundColor Gray
    Write-Host "  Lineas totales: $totalLines" -ForegroundColor Gray
    Write-Host "  Codigo:        $codeLines lineas" -ForegroundColor Green
    Write-Host "  Comentarios:   $commentLines lineas" -ForegroundColor Yellow
    Write-Host "  En blanco:     $blankLines lineas" -ForegroundColor Gray
    Write-Host "  Funciones:     $functionCount" -ForegroundColor Cyan
    Write-Host "  Regiones:      $regionCount" -ForegroundColor Cyan
}

# --- Phase 3: Verify structure ---
Write-Host ""
Write-Host "[3/3] Verificando estructura del proyecto..." -ForegroundColor Yellow

$requiredFiles = @(
    "FEN-Bloat.ps1",
    "README.md",
    "assets\fenreitsu.png",
    "assets\fenreitsu-white.png"
)

$allOk = $true
foreach ($file in $requiredFiles) {
    $path = Join-Path $projectRoot $file
    if (Test-Path $path) {
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allOk = $false
    }
}

# Check required directories
$requiredDirs = @("Logs", "Config", "Backups")
foreach ($dir in $requiredDirs) {
    $path = Join-Path $projectRoot $dir
    if (-not (Test-Path $path)) {
        $null = New-Item -Path $path -ItemType Directory -Force
        Write-Host "  [CREATED] $dir\" -ForegroundColor Yellow
    }
}

# Verify the script contains all required regions
$content = Get-Content -Path $mainScript -Raw -Encoding UTF8
$regions = @(
    "REGION 1", "REGION 2", "REGION 3", "REGION 4",
    "REGION 5", "REGION 6", "REGION 7", "REGION 8", "REGION 9"
)

Write-Host ""
Write-Host "  Verificando regiones del script:" -ForegroundColor Gray
foreach ($region in $regions) {
    if ($content -match $region) {
        Write-Host "  [OK] $region" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $region" -ForegroundColor Red
        $allOk = $false
    }
}

# --- Summary ---
$buildTime = ((Get-Date) - $buildStart).TotalMilliseconds

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan

if ($allOk) {
    Write-Host "  COMPILACION EXITOSA" -ForegroundColor Green
} else {
    Write-Host "  COMPILACION COMPLETADA CON ADVERTENCIAS" -ForegroundColor Yellow
}

Write-Host "  Tiempo: $([math]::Round($buildTime, 0)) ms" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

exit 0
