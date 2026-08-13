# Більярд Онлайн: підняти гру + публічне посилання (Cloudflare, а як заблокований — localhost.run)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-Tcp($TargetHost, $Port, $Ms) {
  try {
    $tc = New-Object Net.Sockets.TcpClient
    $ok = $tc.ConnectAsync($TargetHost, $Port).Wait($Ms) -and $tc.Connected
    $tc.Close(); return $ok
  } catch { return $false }
}

$script:browserOpened = $false
function Show-Link($url) {
  try { Set-Clipboard -Value $url } catch {}
  Write-Host ""
  Write-Host "  ==================================================================" -ForegroundColor Green
  Write-Host "   ПОСИЛАННЯ ДЛЯ ДРУГА (вже скопійовано в буфер обміну):" -ForegroundColor Green
  Write-Host "   $url" -ForegroundColor Yellow
  Write-Host "  ==================================================================" -ForegroundColor Green
  Write-Host ""
  Write-Host "   1. Кинь це посилання другові (Telegram/Viber/будь-де)"
  Write-Host "   2. Відкрий його і в себе"
  Write-Host "   3. Тисни `"Створити гру онлайн`" і дай другові КОД із екрана,"
  Write-Host "      або тисни `"Скопіювати посилання`" — там код уже вшитий"
  Write-Host ""
  Write-Host "   Це вікно має лишатися відкритим, поки граєте." -ForegroundColor DarkGray
  Write-Host "   Щойно партія стартувала — з'єднання пряме, тунель більше не критичний." -ForegroundColor DarkGray
  Write-Host ""
  if (-not $script:browserOpened) { $script:browserOpened = $true; Start-Process $url }
}

Write-Host ""
Write-Host "  🎱 БІЛЬЯРД ОНЛАЙН" -ForegroundColor Yellow
Write-Host ""

# 1) Веб-сервер гри (якщо ще не запущений)
if (Test-Tcp "127.0.0.1" 3199 400) {
  Write-Host "  Сервер гри вже працює на http://localhost:3199"
} else {
  Start-Process -WindowStyle Minimized node -ArgumentList "`"$here\server.js`""
  Write-Host "  Запустив сервер гри на http://localhost:3199"
}

# 2) Який тунель доступний?
$cf = $null
if (Get-Command cloudflared -ErrorAction SilentlyContinue) { $cf = "cloudflared" }
elseif (Test-Path "$here\cloudflared.exe") { $cf = "$here\cloudflared.exe" }

$useCf = $false
if ($cf) {
  Write-Host "  Перевіряю доступність Cloudflare..."
  $useCf = Test-Tcp "api.trycloudflare.com" 443 5000
  if (-not $useCf) { Write-Host "  Cloudflare недоступний із цієї мережі — беру localhost.run" -ForegroundColor DarkYellow }
}

# Анонімні тунелі періодично рвуться (localhost.run — кожні ~10-15 хв),
# тому крутимось у циклі: відпав — перепідключаємось і показуємо СВІЖЕ посилання.
$lastUrl = ""
$everGot = $false
while ($true) {
  if ($useCf) {
    Write-Host "  Створюю посилання через Cloudflare..."
    & $cf tunnel --no-autoupdate --url http://localhost:3199 2>&1 | ForEach-Object {
      $line = "$_"
      if ($line -match "https://[a-z0-9-]+\.trycloudflare\.com") {
        $u = $Matches[0]
        if ($u -ne $lastUrl) { $lastUrl = $u; $everGot = $true; Show-Link $u }
      }
    }
  } else {
    Write-Host "  Створюю посилання через localhost.run..."
    ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o ServerAliveInterval=20 -R 80:localhost:3199 nokey@localhost.run 2>&1 | ForEach-Object {
      $line = "$_"
      if ($line -match "https://[a-z0-9]+\.lhr\.life") {
        $u = $Matches[0]
        if ($u -ne $lastUrl) { $lastUrl = $u; $everGot = $true; Show-Link $u }
      }
    }
  }
  if (-not $everGot) {
    Write-Host ""
    Write-Host "  ❌ Не вдалося створити тунель. Перевір інтернет і спробуй ще раз." -ForegroundColor Red
    Write-Host "     Запасний варіант: просто надішли другові файл index.html" -ForegroundColor DarkGray
    break
  }
  Write-Host ""
  Write-Host "  ⚠ Тунель відпав — перепідключаюсь (посилання зміниться!)..." -ForegroundColor DarkYellow
  Start-Sleep -Seconds 2
}
