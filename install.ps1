# ============================================================
#  Grably - One-Click Installer
#  Run as Administrator in PowerShell:
#  iwr -useb https://raw.githubusercontent.com/Ahsaan-Ullah/Installgrably/refs/heads/main/install.ps1 | iex
# ============================================================

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── Config ──
$AppName       = "Grably"
$InstallDir    = "C:\Grably"
$BinDir        = "$InstallDir\bin"
$DesktopLink   = "$env:USERPROFILE\Desktop\Grably.lnk"
$StartMenuDir  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$StartMenuLink = "$StartMenuDir\Grably.lnk"

$DownloadURL   = "http://qsrtools.shop/grably_beta.zip"
$ZipFile       = "$env:TEMP\grably_install.zip"

$YtDlpURL      = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
$FfmpegURL     = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
$DenoURL       = "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip"

# ── UI Helpers ──
function Write-Step  { param($msg) Write-Host "`n  [$script:step] $msg" -ForegroundColor Cyan; $script:step++ }
function Write-OK    { param($msg) Write-Host "      [OK] $msg" -ForegroundColor Green }
function Write-Skip  { param($msg) Write-Host "      [SKIP] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "      [FAIL] $msg" -ForegroundColor Red }
$script:step = 1

# ── Admin Check ──
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`n  [ERROR] Please run PowerShell as Administrator!" -ForegroundColor Red
    Write-Host "  Right-click PowerShell -> Run as Administrator`n" -ForegroundColor Yellow
    pause
    exit 1
}

# ── Banner ──
Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Magenta
Write-Host "       Grably - Video Downloader Installer" -ForegroundColor White
Write-Host "  ==========================================" -ForegroundColor Magenta
Write-Host ""

# ── Step 1: Create install directory ──
Write-Step "Creating install directory..."
if (Test-Path $InstallDir) {
    Write-Skip "$InstallDir already exists (upgrading)"
} else {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-OK "Created $InstallDir"
}
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

# ── Step 2: Download Grably ──
Write-Step "Downloading Grably..."
try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $DownloadURL -OutFile $ZipFile -UseBasicParsing
    Write-OK "Downloaded successfully"
} catch {
    # Fallback: curl
    try {
        curl.exe -L --fail -o $ZipFile $DownloadURL 2>$null
        Write-OK "Downloaded via curl"
    } catch {
        Write-Err "Download failed: $_"
        pause; exit 1
    }
}

# ── Step 3: Extract ──
Write-Step "Extracting files..."
try {
    Expand-Archive -Path $ZipFile -DestinationPath $InstallDir -Force
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Write-OK "Extracted to $InstallDir"
} catch {
    Write-Err "Extraction failed: $_"
    pause; exit 1
}

# ── Step 7: Create Desktop Shortcut ──
Write-Step "Creating shortcuts..."
$exePath = "$InstallDir\Grably.exe"
if (Test-Path $exePath) {
    try {
        $WshShell = New-Object -ComObject WScript.Shell

        # Desktop shortcut
        $Shortcut = $WshShell.CreateShortcut($DesktopLink)
        $Shortcut.TargetPath = $exePath
        $Shortcut.WorkingDirectory = $InstallDir
        $Shortcut.IconLocation = "$InstallDir\icons\icon.ico"
        $Shortcut.Description = "Grably - Advanced Video Downloader"
        $Shortcut.Save()
        Write-OK "Desktop shortcut created"

        # Start Menu shortcut
        $Shortcut2 = $WshShell.CreateShortcut($StartMenuLink)
        $Shortcut2.TargetPath = $exePath
        $Shortcut2.WorkingDirectory = $InstallDir
        $Shortcut2.IconLocation = "$InstallDir\icons\icon.ico"
        $Shortcut2.Description = "Grably - Advanced Video Downloader"
        $Shortcut2.Save()
        Write-OK "Start Menu shortcut created"
    } catch {
        Write-Err "Shortcut creation failed: $_"
    }
} else {
    Write-Err "Grably.exe not found at $exePath"
}

# ── Step 8: Add to PATH (optional) ──
Write-Step "Adding to system PATH..."
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$InstallDir*") {
    try {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "Machine")
        Write-OK "Added $InstallDir to PATH"
    } catch {
        Write-Skip "Could not add to PATH (non-critical)"
    }
} else {
    Write-Skip "Already in PATH"
}

# ── Done ──
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Green
Write-Host "       Grably installed successfully!" -ForegroundColor White
Write-Host "  ==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Install location : $InstallDir" -ForegroundColor Gray
Write-Host "  Desktop shortcut : Grably" -ForegroundColor Gray
Write-Host ""
Write-Host "  You can now close this window and" -ForegroundColor Yellow
Write-Host "  launch Grably from your Desktop!" -ForegroundColor Yellow
Write-Host ""

# Ask to launch
$launch = Read-Host "  Launch Grably now? (Y/N)"
if ($launch -eq "Y" -or $launch -eq "y") {
    Start-Process $exePath -WorkingDirectory $InstallDir
}
