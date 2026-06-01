param(
    [switch]$HeadlessCheck
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectFile = Join-Path $projectRoot "project.godot"
$workspaceRoot = Split-Path -Parent $projectRoot
$godotToolRoot = Join-Path $workspaceRoot "tools\Godot-4.6.3"

if (-not (Test-Path -LiteralPath $projectFile)) {
    Write-Host "Could not find project.godot next to this launcher." -ForegroundColor Red
    exit 1
}

$guiCandidates = @(
    (Join-Path $godotToolRoot "Godot_v4.6.3-stable_win64.exe"),
    (Join-Path $projectRoot "tools\Godot-4.6.3\Godot_v4.6.3-stable_win64.exe"),
    (Join-Path $env:ProgramFiles "Godot\Godot.exe")
)

$consoleCandidates = @(
    (Join-Path $godotToolRoot "Godot_v4.6.3-stable_win64_console.exe"),
    (Join-Path $projectRoot "tools\Godot-4.6.3\Godot_v4.6.3-stable_win64_console.exe")
)

function Find-FirstExistingPath {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

$godotPath = if ($HeadlessCheck) {
    Find-FirstExistingPath -Candidates ($consoleCandidates + $guiCandidates)
} else {
    Find-FirstExistingPath -Candidates ($guiCandidates + $consoleCandidates)
}

if (-not $godotPath) {
    Write-Host "Could not find Godot 4.6.3." -ForegroundColor Red
    Write-Host "Expected it under: $godotToolRoot"
    Write-Host "Install Godot or edit launch_game.ps1 to point at your Godot executable."
    exit 1
}

if ($HeadlessCheck) {
    & $godotPath --headless --path $projectRoot --quit
    exit $LASTEXITCODE
}

Write-Host "Starting Rural Life Demo..."
Write-Host "Godot: $godotPath"
Write-Host "Project: $projectRoot"
Start-Process -FilePath $godotPath -ArgumentList @("--path", $projectRoot)
