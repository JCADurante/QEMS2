@echo off
setlocal
cd /d "%~dp0"
git remote get-url origin >nul 2>nul
if errorlevel 1 (
  echo GitHub remote is not connected yet. Ask Codex to connect the private repository first.
  pause
  exit /b 1
)
git add -- .github .gitattributes .gitignore AGENTS.md README.md package.json src app scripts tests fixtures "Publish Source.bat"
if errorlevel 1 goto failed
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "Update QEMS application source"
  if errorlevel 1 goto failed
)
git push -u origin main
if errorlevel 1 goto failed
echo Source published. Check GitHub Actions for the tested portable package.
pause
exit /b 0
:failed
echo Publish failed. Your local source and server data are retained.
pause
exit /b 1
