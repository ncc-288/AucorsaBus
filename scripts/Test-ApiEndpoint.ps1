<#
.SYNOPSIS
    Tests a specific API endpoint with detailed output

.PARAMETER Url
    The full URL to test

.PARAMETER Nonce
    The nonce value to use (optional, will fetch if not provided)

.EXAMPLE
    .\Test-ApiEndpoint.ps1 -Url "https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop?line=2&stop_id=1"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$false)]
    [string]$Nonce
)

# Get nonce if not provided
if (-not $Nonce) {
    Write-Host "Getting nonce..." -ForegroundColor Yellow
    $Nonce = & "$PSScriptRoot\Get-ApiNonce.ps1"
    if (-not $Nonce) {
        Write-Error "Failed to get nonce"
        exit 1
    }
}

# Add nonce to URL if not present
if ($Url -notlike "*_wpnonce=*") {
    $separator = if ($Url -like "*?*") { "&" } else { "?" }
    $Url = "$Url$separator`_wpnonce=$Nonce"
}

Write-Host "`n=== Testing API Endpoint ===" -ForegroundColor Cyan
Write-Host "URL: $Url" -ForegroundColor White

$start = Get-Date
try {
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    $elapsed = ((Get-Date) - $start).TotalMilliseconds
    
    Write-Host "`n✅ SUCCESS" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor White
    Write-Host "Time: $([math]::Round($elapsed))ms" -ForegroundColor White
    Write-Host "Content-Type: $($response.Headers.'Content-Type')" -ForegroundColor White
    Write-Host "Content-Length: $($response.Content.Length) bytes" -ForegroundColor White
    
    Write-Host "`nResponse Body:" -ForegroundColor Cyan
    Write-Host "---START---" -ForegroundColor Gray
    Write-Host $response.Content
    Write-Host "---END---" -ForegroundColor Gray
    
    return @{
        Success = $true
        StatusCode = $response.StatusCode
        Time = $elapsed
        Content = $response.Content
    }
    
} catch {
    $elapsed = ((Get-Date) - $start).TotalMilliseconds
    Write-Host "`n❌ FAILED" -ForegroundColor Red
    Write-Host "Time: $([math]::Round($elapsed))ms" -ForegroundColor White
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    return @{
        Success = $false
        Time = $elapsed
        Error = $_.Exception.Message
    }
}
