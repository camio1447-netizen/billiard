@echo off
chcp 65001 >nul
title Більярд Онлайн — Cloudflare
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-online.ps1"
pause
