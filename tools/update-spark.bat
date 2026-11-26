@echo off
setlocal
title Update Spark Studio library

rem ======================================================================
rem  Spark Studio library updater for Windows. Just double-click it.
rem
rem  Downloads your newest Pinterest saves and ArtStation likes into your
rem  Spark folder on Google Drive. Images it already has are skipped, so
rem  each run only fetches what is new.
rem
rem  The first time, it asks you to pick your Spark folder (the Google
rem  Drive folder Spark Studio is connected to) and remembers it.
rem ======================================================================
set "PINTEREST_URL=https://www.pinterest.com/JasonLayel/"
set "ARTSTATION_URL=https://www.artstation.com/jasonlayel/likes"
rem Browser you're logged in to Pinterest with: firefox, chrome or edge
set "BROWSER=firefox"

set "DATA_DIR=%LOCALAPPDATA%\SparkStudio"
set "ARCHIVE=%DATA_DIR%\gdl-archive.sqlite3"
set "SPARK_CFG=%DATA_DIR%\spark-folder.txt"
if not exist "%DATA_DIR%\" mkdir "%DATA_DIR%"

set "SPARK_DIR="
if exist "%SPARK_CFG%" set /p SPARK_DIR=<"%SPARK_CFG%"
if not defined SPARK_DIR goto :pick
if not exist "%SPARK_DIR%\" goto :pick
echo Spark folder: %SPARK_DIR%
echo.
choice /c SC /t 10 /d S /m "S = start now, C = choose a different folder (starts by itself in 10s)"
if errorlevel 2 goto :pick
goto :havefolder

:pick
echo A window will open. Choose your Spark folder: the Google Drive
echo folder that Spark Studio is connected to.
powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.Form -Property @{TopMost = $true}; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Choose your Spark folder - the Google Drive folder Spark Studio is connected to'; $d.ShowNewFolderButton = $false; if ($d.ShowDialog($f) -eq 'OK') { Set-Content -LiteralPath $env:SPARK_CFG -Value $d.SelectedPath }"
set "SPARK_DIR="
if exist "%SPARK_CFG%" set /p SPARK_DIR=<"%SPARK_CFG%"
if not defined SPARK_DIR goto :nofolder
if not exist "%SPARK_DIR%\" goto :nofolder
echo Spark folder: %SPARK_DIR%

:havefolder
set "PY="
where py >nul 2>nul && set "PY=py"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY goto :nopython

echo.
echo Updating gallery-dl...
%PY% -m pip install --quiet --upgrade gallery-dl
if errorlevel 1 goto :nopip

echo.
echo [1/2] Pinterest: %PINTEREST_URL%
%PY% -m gallery_dl --cookies-from-browser %BROWSER% --download-archive "%ARCHIVE%" --sleep-request 0.5 -d "%SPARK_DIR%" "%PINTEREST_URL%"

echo.
echo [2/2] ArtStation: %ARTSTATION_URL%
%PY% -m gallery_dl --download-archive "%ARCHIVE%" --sleep-request 0.5 -d "%SPARK_DIR%" "%ARTSTATION_URL%"

echo.
echo Done. When Google Drive finishes syncing, press Refresh in Spark Studio.
pause
exit /b 0

:nofolder
echo No Spark folder chosen. Double-click the updater again to pick it.
pause
exit /b 1

:nopython
echo Python isn't installed. Install it from python.org/downloads
echo and tick "Add python.exe to PATH" in the installer, then run this again.
pause
exit /b 1

:nopip
echo Couldn't install gallery-dl. Check your internet connection and try again.
pause
exit /b 1
