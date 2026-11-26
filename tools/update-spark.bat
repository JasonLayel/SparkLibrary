@echo off
setlocal
title Update Spark Studio library

rem ======================================================================
rem  Spark Studio library updater for Windows
rem
rem  Downloads your newest Pinterest saves and ArtStation likes into your
rem  Spark folder on Google Drive. Images it already has are skipped, so
rem  each run only fetches what is new. Double-click to run.
rem
rem  ONE-TIME SETUP: set SPARK_DIR to your Spark folder as it appears in
rem  Google Drive for desktop. Open the folder in File Explorer, click the
rem  address bar, and copy the path.
rem ======================================================================
set "SPARK_DIR=G:\My Drive\Spark"

set "PINTEREST_URL=https://www.pinterest.com/JasonLayel/"
set "ARTSTATION_URL=https://www.artstation.com/jasonlayel/likes"
rem Browser you're logged in to Pinterest with: firefox, chrome or edge
set "BROWSER=firefox"
rem gallery-dl's record of what it has already downloaded, kept on this PC
set "ARCHIVE_DIR=%LOCALAPPDATA%\SparkStudio"
set "ARCHIVE=%ARCHIVE_DIR%\gdl-archive.sqlite3"

if not exist "%SPARK_DIR%\" goto :nofolder

set "PY="
where py >nul 2>nul && set "PY=py"
if not defined PY where python >nul 2>nul && set "PY=python"
if not defined PY goto :nopython

if not exist "%ARCHIVE_DIR%\" mkdir "%ARCHIVE_DIR%"

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
echo Can't find your Spark folder:
echo     %SPARK_DIR%
echo Right-click update-spark.bat, choose Edit, and fix the SPARK_DIR line.
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
