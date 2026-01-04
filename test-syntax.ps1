# Syntax validation script
$scriptDir = $PSScriptRoot
$scripts = Get-ChildItem -Path $scriptDir -Recurse -Filter "*.ps1" | Where-Object { $_.Name -ne "test-syntax.ps1" }

Write-Host "`n  DEVBOX FACTORY - SYNTAX VALIDATION" -ForegroundColor Cyan
Write-Host "  ===================================`n" -ForegroundColor Cyan

$errorCount = 0
$passCount = 0

foreach ($script in $scripts) {
    $relativePath = $script.FullName.Replace($scriptDir, "").TrimStart("\")
    Write-Host "  Checking: $relativePath... " -NoNewline

    try {
        $content = Get-Content $script.FullName -Raw -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)

        if ($errors.Count -gt 0) {
            Write-Host "[FAIL]" -ForegroundColor Red
            foreach ($err in $errors) {
                Write-Host "    Line $($err.Token.StartLine): $($err.Message)" -ForegroundColor Red
            }
            $errorCount++
        } else {
            Write-Host "[PASS]" -ForegroundColor Green
            $passCount++
        }
    } catch {
        Write-Host "[ERROR]" -ForegroundColor Red
        Write-Host "    $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n  -----------------------------------"
Write-Host "  Results: $passCount passed, $errorCount failed`n"

if ($errorCount -eq 0) {
    Write-Host "  All scripts passed syntax validation!`n" -ForegroundColor Green
} else {
    Write-Host "  Some scripts have syntax errors.`n" -ForegroundColor Red
}
