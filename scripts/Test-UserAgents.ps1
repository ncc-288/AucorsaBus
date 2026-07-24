<#
.SYNOPSIS
    Tests API with different User-Agent headers

.PARAMETER StopId
    Stop ID to test (default: 256)

.PARAMETER LineId
    Line ID to test (default: 706)

.EXAMPLE
    .\Test-UserAgents.ps1
    .\Test-UserAgents.ps1 -StopId 1 -LineId 2
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$StopId = "256",
    
    [Parameter(Mandatory=$false)]
    [string]$LineId = "706"
)

Write-Host "=== Testing API with Different User-Agents ===" -ForegroundColor Cyan
Write-Host "Stop: $StopId, Line: $LineId`n" -ForegroundColor White

# Get nonce
Write-Host "Getting nonce..." -ForegroundColor Yellow
$nonce = & "$PSScriptRoot\Get-ApiNonce.ps1"
if (-not $nonce) {
    Write-Error "Failed to get nonce"
    exit 1
}
Write-Host "✓ Nonce: $($nonce.Substring(0,10))...`n" -ForegroundColor Green

$userAgents = @(
    @{
        name = "Desktop Chrome (Windows)"
        ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"
    },
    @{
        name = "Mobile Chrome (Android)"
        ua = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Mobile Safari/537.36"
    },
    @{
        name = "Default PowerShell"
        ua = $null
    }
)

$endpoints = @(
    @{name = "aucorsa.es"; url = "https://aucorsa.es/wp-json/aucorsa/v1/estimations/stop"},
    @{name = "lightapi.aucorsa.es"; url = "https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop"}
)

foreach ($endpoint in $endpoints) {
    Write-Host "=== $($endpoint.name) ===" -ForegroundColor Cyan
    
    foreach ($agent in $userAgents) {
        Write-Host "`n$($agent.name):" -ForegroundColor Yellow
        
        $url = "$($endpoint.url)?line=$LineId&current_line=$LineId&stop_id=$StopId&_wpnonce=$nonce"
        
        $start = Get-Date
        try {
            $headers = @{}
            if ($agent.ua) {
                $headers["User-Agent"] = $agent.ua
            }
            
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers $headers -TimeoutSec 10 -ErrorAction Stop
            $elapsed = ((Get-Date) - $start).TotalMilliseconds
            
            Write-Host "  ✅ Status: $($response.StatusCode)" -ForegroundColor Green
            Write-Host "  Time: $([math]::Round($elapsed))ms" -ForegroundColor White
            Write-Host "  Content-Length: $($response.Content.Length) bytes" -ForegroundColor Gray
            
            # Check response content
            if ($response.Content -match "ppp-no-estimations|Sin estimaci") {
                Write-Host "  Response: No estimations (expected at late hour)" -ForegroundColor Cyan
            } elseif ($response.Content -match "ximo autob") {
                Write-Host "  Response: Has bus times" -ForegroundColor Green
            } else {
                Write-Host "  Response: Unknown format" -ForegroundColor Yellow
            }
            
        } catch {
            $elapsed = ((Get-Date) - $start).TotalMilliseconds
            Write-Host "  ❌ FAILED after $([math]::Round($elapsed))ms" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}
