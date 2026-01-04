# DevBox Factory - Complete Validation Script
Write-Host ""
Write-Host "  DEVBOX FACTORY - COMPLETE VALIDATION" -ForegroundColor Cyan
Write-Host "  =====================================" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# PowerShell Scripts
Write-Host "  POWERSHELL SCRIPTS" -ForegroundColor Yellow
Write-Host "  ------------------" -ForegroundColor DarkGray
Get-ChildItem -Path . -Recurse -Filter "*.ps1" | Where-Object { $_.FullName -notmatch "\\\.claude\\" } | ForEach-Object {
    Write-Host "  Checking: $($_.Name)... " -NoNewline
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    if ($errors.Count -eq 0) {
        Write-Host "[PASS]" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "[FAIL]" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "    Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red }
        $script:failed++
    }
}

Write-Host ""
Write-Host "  JSON FILES" -ForegroundColor Yellow
Write-Host "  ----------" -ForegroundColor DarkGray
Get-ChildItem -Path . -Recurse -Filter "*.json" | Where-Object { $_.FullName -notmatch "\\\.claude\\" } | ForEach-Object {
    Write-Host "  Checking: $($_.Name)... " -NoNewline
    try {
        $null = Get-Content $_.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host "[PASS]" -ForegroundColor Green
        $script:passed++
    } catch {
        Write-Host "[FAIL]" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host ""
Write-Host "  XML FILES" -ForegroundColor Yellow
Write-Host "  ---------" -ForegroundColor DarkGray
Get-ChildItem -Path . -Recurse -Filter "*.xml" | ForEach-Object {
    Write-Host "  Checking: $($_.Name)... " -NoNewline
    try {
        $null = [xml](Get-Content $_.FullName -Raw -ErrorAction Stop)
        Write-Host "[PASS]" -ForegroundColor Green
        $script:passed++
    } catch {
        Write-Host "[FAIL]" -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host ""
Write-Host "  MARKDOWN FILES" -ForegroundColor Yellow
Write-Host "  --------------" -ForegroundColor DarkGray
Get-ChildItem -Path . -Recurse -Filter "*.md" | ForEach-Object {
    Write-Host "  Checking: $($_.Name)... " -NoNewline
    if (Test-Path $_.FullName) {
        $size = [math]::Round($_.Length / 1KB, 1)
        Write-Host "[PASS] (${size}KB)" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "[FAIL]" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host ""
Write-Host "  -----------------------------------" -ForegroundColor DarkGray
Write-Host "  Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($failed -eq 0) {
    Write-Host "  All files validated successfully!" -ForegroundColor Green
} else {
    Write-Host "  Some files have issues. Please fix them." -ForegroundColor Red
}
Write-Host ""
