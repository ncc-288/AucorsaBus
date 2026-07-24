<#
.SYNOPSIS
    Compares performance between aucorsa.es and lightapi.aucorsa.es

.PARAMETER StopId
    Stop ID to test

.PARAMETER LineId
    Line ID to test

.EXAMPLE
    .\Compare-ApiEndpoints.ps1 -StopId 256 -LineId 706
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$StopId,
    
    [Parameter(Mandatory=$true)]
    [string]$LineId
)

Write-Host "=== Comparing API Endpoints ===" -ForegroundColor Cyan
Write-Host "Stop: $StopId, Line: $LineId`n" -ForegroundColor White

# Get nonce
$nonce = & "$PSScriptRoot\Get-ApiNonce.ps1"
if (-not $nonce) {
    Write-Error "Failed to get nonce"
    exit 1
}

$endpoints = @(
    @{name="aucorsa.es"; url="https://aucorsa.es/wp-json/aucorsa/v1/estimations/stop"},
    @{name="lightapi.aucorsa.es"; url="https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop"}
)

foreach ($endpoint in $endpoints) {
    Write-Host "$($endpoint.name):" -ForegroundColor Yellow
    $times = @()
    
    for ($i = 1; $i -le 5; $i++) {
        $start = Get-Date
        try {
            $url = "$($endpoint.url)?line=$LineId&current_line=$LineId&stop_id=$StopId&_wpnonce=$nonce"
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
            $elapsed = ((Get-Date) - $start).TotalMilliseconds
            $times += $elapsed
            Write-Host "   Request $i`: $($response.StatusCode) - $([math]::Round($elapsed))ms" -ForegroundColor Green
        } catch {
            $elapsed = ((Get-Date) - $start).TotalMilliseconds
            $times += $elapsed
            Write-Host "   Request $i`: FAILED - $([math]::Round($elapsed))ms" -ForegroundColor Red
        }
    }
    
    $avg = ($times | Measure-Object -Average).Average
    Write-Host "   Average: $([math]::Round($avg))ms`n" -ForegroundColor Cyan
}
