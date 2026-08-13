@echo off
chcp 65001 >nul
title Оновлення сайту гри
node "%~dp0update-site.js"
pause
