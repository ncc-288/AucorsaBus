<#
.SYNOPSIS
    Tests fetching all estimations for a specific line

.PARAMETER LineId
    The line ID to test (e.g., "2", "706")

.PARAMETER ParallelCount
    Number of parallel requests (default: all at once)

.EXAMPLE
    .\Test-LineEstimations.ps1 -LineId 2
    .\Test-LineEstimations.ps1 -LineId 706 -ParallelCount 8
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$LineId,
    
    [Parameter(Mandatory=$false)]
    [int]$ParallelCount = 0
)

Write-Host "=== Testing Line $LineId Estimations ===" -ForegroundColor Cyan

# Get nonce
Write-Host "`n1️⃣ Getting nonce..." -ForegroundColor Yellow
$nonce = & "$PSScriptRoot\Get-ApiNonce.ps1"
if (-not $nonce) {
    Write-Error "Failed to get nonce"
    exit 1
}
Write-Host "   ✓ Nonce: $($nonce.Substring(0,10))..." -ForegroundColor Green

# Get line stops
Write-Host "`n2️⃣ Fetching stops for line $LineId..." -ForegroundColor Yellow
$url = "https://aucorsa.es/wp-json/aucorsa/v1/map/nodes?line_id=$LineId&mode=complete&_wpnonce=$nonce"

$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$data = $response.Content | ConvertFrom-Json

$allStops = @()
foreach ($collection in $data) {
    $stops = $collection.features | Where-Object { $_.geometry.type -eq "Point" }
    foreach ($stop in $stops) {
        $allStops += $stop.id
    }
}

Write-Host "   ✓ Found $($allStops.Count) stops" -ForegroundColor Green

# Test lightapi.aucorsa.es
Write-Host "`n3️⃣ Testing lightapi.aucorsa.es (parallel)..." -ForegroundColor Yellow
$startTime = Get-Date
$jobs = @()

foreach ($stopId in $allStops) {
    $jobs += Start-Job -ScriptBlock {
        param($stopId, $lineId, $nonce)
        $start = Get-Date
        try {
            $url = "https://lightapi.aucorsa.es/wp-json/aucorsa/v1/estimations/stop?line=$lineId&current_line=$lineId&stop_id=$stopId&_wpnonce=$nonce"
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
            $elapsed = ((Get-Date) - $start).TotalMilliseconds
            return @{success=$true; time=$elapsed; stopId=$stopId}
        } catch {
            $elapsed = ((Get-Date) - $start).TotalMilliseconds
            return @{success=$false; time=$elapsed; stopId=$stopId; error=$_.Exception.Message}
        }
    } -ArgumentList $stopId, $LineId, $nonce
}

Wait-Job $jobs | Out-Null
$totalTime = ((Get-Date) - $startTime).TotalMilliseconds
$results = $jobs | Receive-Job
$jobs | Remove-Job -Force

$successCount = ($results | Where-Object {$_.success -eq $true}).Count
$failCount = ($results | Where-Object {$_.success -eq $false}).Count

Write-Host "`n📊 Results:" -ForegroundColor Cyan
Write-Host "   Total stops: $($allStops.Count)" -ForegroundColor White
Write-Host "   Successful: $successCount" -ForegroundColor Green
Write-Host "   Failed: $failCount" -ForegroundColor $(if($failCount -gt 0){"Red"}else{"Green"})
Write-Host "   Total time: $([math]::Round($totalTime/1000, 1))s" -ForegroundColor Yellow

if ($successCount -gt 0) {
    $avgTime = ($results | Where-Object {$_.success} | Measure-Object -Property time -Average).Average
    Write-Host "   Avg request time: $([math]::Round($avgTime))ms" -ForegroundColor White
}

if ($failCount -gt 0) {
    Write-Host "`n⚠️  Failed stops:" -ForegroundColor Yellow
    $failed = $results | Where-Object {-not $_.success} | Select-Object -First 3
    foreach ($f in $failed) {
        Write-Host "   Stop $($f.stopId): $($f.error)" -ForegroundColor Red
    }
}
