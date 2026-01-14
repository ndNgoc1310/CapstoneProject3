@echo off
setlocal enabledelayedexpansion

:: Prompt for current and new testbench names
set /p OLD_TB=Enter the CURRENT testbench name (e.g., testbench): 
set /p NEW_TB=Enter the NEW testbench name (e.g., alu_tb): 

if "%OLD_TB%"=="" (
    echo No current testbench name entered. Aborting.
    goto end
)

if "%NEW_TB%"=="" (
    echo No new testbench name entered. Aborting.
    goto end
)

:: Define the relative path to the target simulation folder
set "TARGET_DIR=..\10_sim\verilator"
set BACKUP_DIR=%TARGET_DIR%\Backups

:: List of files to update
set FILES=makefile flist

:: Backup original files
echo Backing up original files to %BACKUP_DIR%...
for %%F in (%FILES%) do (
    if exist "%TARGET_DIR%\%%F" (
        copy /Y "%TARGET_DIR%\%%F" "%BACKUP_DIR%\%%F.bak" > nul
    )
)

:: Perform replacements using PowerShell
echo Replacing "%OLD_TB%" with "%NEW_TB%" in target files...
for %%F in (%FILES%) do (
    if exist "%TARGET_DIR%\%%F" (
        powershell -Command ^
        "$text = Get-Content -Raw '%TARGET_DIR%\%%F';" ^
        "$text = $text -replace 'TOP=%OLD_TB%', 'TOP=%NEW_TB%';" ^
        "$text = $text -replace '--exe %OLD_TB%.cpp', '--exe %NEW_TB%.cpp';" ^
        "$text = $text -replace '-top %OLD_TB%', '-top %NEW_TB%';" ^
        "Set-Content '%TARGET_DIR%\%%F' $text"
    ) else (
        echo File not found: %%F
    )
)

echo Done updating testbench references.

:end
pause
endlocal