@echo off
setlocal enabledelayedexpansion

rem --- Configurable indicators ---
set "A1_VERSION=1.14.1"
set "A2_VERSION=0.30.4"
set "PLAIN_VERSION=4.2.1"
set "C2_DOMAIN=sfrclak.com"
set "C2_IP=142.11.206.73"

rem --- Helper: check required commands ---
where findstr >nul 2>&1 || (echo ERROR: findstr not found & pause & exit /b 1)
where dir >nul 2>&1 || (echo ERROR: dir not found & pause & exit /b 1)

rem --- Determine npm cache location if npm available ---
set "NPM_CACHE=%APPDATA%\npm-cache"
where npm >nul 2>&1
if %ERRORLEVEL%==0 (
  for /f "usebackq delims=" %%C in (`npm config get cache 2^>nul`) do set "NPM_CACHE=%%C"
)

echo === Axios compromise quick-check ===
echo Scanning for affected package versions and artifacts...
echo.

rem --- Scan node_modules directories (project trees) ---
echo -- Scanning project node_modules for affected versions --
for /f "delims=" %%D in ('dir /b /s /ad node_modules 2^>nul') do (
  set "MODULE_DIR=%%D"
  if exist "%%D\axios\package.json" (
    findstr /i /r "\"version\"\s*:\s*\"%A1_VERSION%\"" "%%D\axios\package.json" >nul && echo FOUND: %%D\axios version %A1_VERSION% && echo Location: %%D\axios
    findstr /i /r "\"version\"\s*:\s*\"%A2_VERSION%\"" "%%D\axios\package.json" >nul && echo FOUND: %%D\axios version %A2_VERSION% && echo Location: %%D\axios
  )
  if exist "%%D\plain-crypto-js\package.json" (
    findstr /i /r "\"version\"\s*:\s*\"%PLAIN_VERSION%\"" "%%D\plain-crypto-js\package.json" >nul && echo FOUND: %%D\plain-crypto-js version %PLAIN_VERSION% && echo Location: %%D\plain-crypto-js
  )
)

rem --- Check common global npm location (APPDATA) ---
echo.
echo -- Checking global npm location (%APPDATA%\npm\node_modules) --
set "G1=%APPDATA%\npm\node_modules"
if exist "%G1%\axios\package.json" (
  findstr /i /r "\"version\"\s*:\s*\"%A1_VERSION%\"" "%G1%\axios\package.json" >nul && echo FOUND (global): %G1%\axios version %A1_VERSION%
  findstr /i /r "\"version\"\s*:\s*\"%A2_VERSION%\"" "%G1%\axios\package.json" >nul && echo FOUND (global): %G1%\axios version %A2_VERSION%
)
if exist "%G1%\plain-crypto-js\package.json" (
  findstr /i /r "\"version\"\s*:\s*\"%PLAIN_VERSION%\"" "%G1%\plain-crypto-js\package.json" >nul && echo FOUND (global): %G1%\plain-crypto-js version %PLAIN_VERSION%
)

rem --- DNS cache (may require admin) ---
echo.
echo -- Checking DNS cache for %C2_DOMAIN% --
ipconfig /displaydns 2>nul | findstr /i "%C2_DOMAIN%" >nul && echo WARNING: DNS cache contains %C2_DOMAIN%

rem --- Network connections (IP-based check is most reliable) ---
echo.
echo -- Checking active connections for %C2_IP% --
netstat -ano 2>nul | findstr /i "%C2_IP%" >nul && echo WARNING: Active/netstat contains %C2_IP%

rem --- Search npm cache for tarballs and compute SHA256 (certutil required) ---
echo.
echo -- Searching npm cache (%NPM_CACHE%) for axios/plain-crypto-js tarballs --
where certutil >nul 2>&1
if %ERRORLEVEL%==0 (
  for /f "delims=" %%F in ('dir /b /s "%NPM_CACHE%\*axios*.tgz" 2^>nul') do (
    echo Found tarball: "%%F"
    for /f "tokens=2*" %%H in ('certutil -hashfile "%%F" SHA256 ^| findstr /i /v "certutil" ^| findstr /i /v "sha256"') do echo SHA256: %%I
  )
  for /f "delims=" %%F in ('dir /b /s "%NPM_CACHE%\*plain-crypto-js*.tgz" 2^>nul') do (
    echo Found tarball: "%%F"
    for /f "tokens=2*" %%H in ('certutil -hashfile "%%F" SHA256 ^| findstr /i /v "certutil" ^| findstr /i /v "sha256"') do echo SHA256: %%I
  )
) else (
  echo Note: certutil not found; skipping tarball hashing.
)

rem --- Known filesystem artifacts (examples) ---
echo.
echo -- Checking for known artifact filenames --
if exist "%PROGRAMDATA%\wt.exe" echo WARNING: Found %PROGRAMDATA%\wt.exe
if exist "%TEMP%\6202033.vbs" echo WARNING: Found %TEMP%\6202033.vbs
if exist "%TEMP%\6202033.ps1" echo WARNING: Found %TEMP%\6202033.ps1

rem --- Final guidance ---
echo.
echo If you found any indicators: isolate the host, rotate credentials that were used on it, audit CI/build agents, and rebuild artifacts using known-good dependency versions.
echo Done.
pause
endlocal
