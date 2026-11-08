@echo off
echo ============================================================================
echo   KAUSAP AI - FIREBASE HOSTING ONE-CLICK BUILD ^& DEPLOY (kausap-ai.web.app)
echo ============================================================================
echo.
cd /d "%~dp0mobile"
echo [1/2] Building Flutter Web Release bundle...
call flutter build web --release --no-pub
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter web build failed.
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo [2/2] Deploying build/web to https://kausap-ai.web.app/ ...
call npx --yes firebase-tools deploy --only hosting --project kausap-ai
echo.
echo ============================================================================
echo   DONE! Hard-refresh https://kausap-ai.web.app/ (Ctrl + Shift + R)
echo ============================================================================
pause
