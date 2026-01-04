# Check for smart quotes and encoding issues
$file = "C:\Projects\Install-ClaudeCode-VibeDev-Ultra\devbox.ps1"
$content = Get-Content $file -Raw

# Check for smart quotes (curly quotes)
$smartQuotes = @(
    [char]8220,  # "
    [char]8221,  # "
    [char]8216,  # '
    [char]8217   # '
)

Write-Host "Checking $file for smart quotes..." -ForegroundColor Cyan
$found = $false
$lineNum = 0
foreach ($line in (Get-Content $file)) {
    $lineNum++
    foreach ($sq in $smartQuotes) {
        if ($line.Contains($sq)) {
            Write-Host "Line $lineNum contains smart quote (code $([int]$sq)): $line" -ForegroundColor Red
            $found = $true
        }
    }
}

if (-not $found) {
    Write-Host "No smart quotes found." -ForegroundColor Green
}

# Try to parse the file
Write-Host "`nTrying to parse file..." -ForegroundColor Cyan
$errors = $null
$tokens = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
if ($errors.Count -gt 0) {
    Write-Host "Parse errors:" -ForegroundColor Red
    $errors | Select-Object -First 5 | ForEach-Object {
        Write-Host "  Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "File parses successfully!" -ForegroundColor Green
}
