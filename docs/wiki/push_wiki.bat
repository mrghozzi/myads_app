@echo off
echo ===================================================
echo Pushing MYADS Mobile App Wiki to GitHub...
echo ===================================================
cd /d "%~dp0"
git push -u origin master
if %errorlevel% equ 0 (
    echo.
    echo ===================================================
    echo SUCCESS! Wiki published to https://github.com/mrghozzi/myads_app/wiki
    echo ===================================================
) else (
    echo.
    echo ===================================================
    echo FAILED: Make sure Wikis feature is enabled in:
    echo https://github.com/mrghozzi/myads_app/settings
    echo ===================================================
)
pause
