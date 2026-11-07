# HabitNova Cloudflare Pages Deployment Script
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Building HabitNova for Web (Release)... " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter web build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Ensure Cloudflare security headers are present in build/web
Copy-Item -Path "web\_headers" -Destination "build\web\_headers" -Force

Write-Host "==========================================" -ForegroundColor Green
Write-Host " Build succeeded! Deploying to Cloudflare... " -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

npx wrangler deploy

