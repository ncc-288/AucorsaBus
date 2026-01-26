<#
.SYNOPSIS
    Aucorsa Bus Estimation Script - Get real-time bus arrival times for Córdoba.

.EXAMPLE
    .\Get-AucorsaEstimation.ps1 -StopId '105'
    .\Get-AucorsaEstimation.ps1 -LineId '706'
#>

param(
    [string]$StopId,
    [string]$LineId,
    [switch]$ListLines,
    [int]$ThrottleLimit = 10
)

$script:AucorsaCache = @{
    nonce       = $null
    fetched_at  = $null
    max_age_min = 60
}

function Initialize-AucorsaSession {
    param([switch]$Force)
    if (-not $Force -and $script:AucorsaCache.nonce -and $script:AucorsaCache.fetched_at) {
        $age = (Get-Date) - $script:AucorsaCache.fetched_at
        if ($age.TotalMinutes -lt $script:AucorsaCache.max_age_min) { return $true }
    }
    try {
        $response = Invoke-WebRequest -Uri "https://aucorsa.es/" -SessionVariable "Global:AucorsaSession" -ErrorAction Stop
        if ($response.Content -match '"ajax_nonce":"(.*?)"') {
            $script:AucorsaCache.nonce = $matches[1]
            $script:AucorsaCache.fetched_at = Get-Date
            return $true
        }
        return $false
    }
    catch { Write-Error "Failed to initialize: $_"; return $false }
}

function Get-AucorsaLines {
    if (-not (Initialize-AucorsaSession)) { return }
    $uri = "https://aucorsa.es/wp-json/aucorsa/v1/autocompletion/line?term=&_wpnonce=$($script:AucorsaCache.nonce)"
    return Invoke-RestMethod -Uri $uri -Method Get -WebSession $Global:AucorsaSession -ErrorAction Stop
}

function Get-LineStopsGrouped {
    param([string]$LineId)
    if (-not (Initialize-AucorsaSession)) { return }
    
    $uri = "https://aucorsa.es/wp-json/aucorsa/v1/map/nodes?line_id=$LineId&mode=complete&_wpnonce=$($script:AucorsaCache.nonce)"
    try {
        $json = Invoke-RestMethod -Uri $uri -Method Get -WebSession $Global:AucorsaSession -ErrorAction Stop
    }
    catch {
        return $null # Return null to indicate failure/fallback
    }
    
    $directions = @()
    for ($i = 0; $i -lt $json.Count; $i++) {
        $coll = $json[$i]
        $stops = $coll.features | Where-Object { $_.geometry.type -eq 'Point' } | ForEach-Object { $_.id }
        
        $dirLabel = "Direction $($i + 1)"
        if ($coll.routeLabel -match '→\s*(.+?)<') {
            $dirLabel = "Hacia " + $matches[1]
        }
        elseif ($i -eq 0) {
            $dirLabel = "Ida"
        }
        else {
            $dirLabel = "Vuelta"
        }
        
        $directions += [PSCustomObject]@{
            Direction = $dirLabel
            StopIds   = $stops
        }
    }
    return $directions
}

function Get-LineStops {
    param([string]$LineId)
    if (-not (Initialize-AucorsaSession)) { return }
    $uri = "https://aucorsa.es/wp-json/aucorsa/v1/autocompletion/stop?post_id=$LineId&_wpnonce=$($script:AucorsaCache.nonce)"
    return Invoke-RestMethod -Uri $uri -Method Get -WebSession $Global:AucorsaSession -ErrorAction Stop
}

function Get-AucorsaEstimation {
    param([string]$StopId, [string]$LineId, [int]$ThrottleLimit = 10)
    
    if (-not (Initialize-AucorsaSession)) { return }
    
    $baseUri = "https://aucorsa.es/wp-json/aucorsa/v1/estimations/stop"
    $nonce = $script:AucorsaCache.nonce
    
    if ($StopId -and -not $LineId) {
        $uri = "$baseUri`?stop_id=$StopId&_wpnonce=$nonce"
        return Get-EstimationsFromHtml -Uri $uri
    }
    elseif ($LineId -and -not $StopId) {
        # Try grouped first
        $directions = Get-LineStopsGrouped -LineId $LineId
        $stopLabels = @{}
        $allStops = Get-LineStops -LineId $LineId
        if ($allStops) { $allStops | ForEach-Object { $stopLabels[$_.id.ToString()] = $_.label } }
        
        if ($directions) {
            foreach ($dir in $directions) {
                Write-Host "`n=== $($dir.Direction) ===" -ForegroundColor Cyan
                Process-Stops -StopIds $dir.StopIds -LineId $LineId -Nonce $nonce -Labels $stopLabels -ThrottleLimit $ThrottleLimit
            }
        }
        else {
            # Fallback to flat list
            Write-Host "`n=== All Stops (Map data unavailable) ===" -ForegroundColor Cyan
            if (-not $allStops) { Write-Error "No stops found for line $LineId"; return }
            $stopIds = $allStops | ForEach-Object { $_.id }
            Process-Stops -StopIds $stopIds -LineId $LineId -Nonce $nonce -Labels $stopLabels -ThrottleLimit $ThrottleLimit
        }
    }
    elseif ($StopId -and $LineId) {
        $uri = "$baseUri`?line=$LineId&current_line=$LineId&stop_id=$StopId&_wpnonce=$nonce"
        return Get-EstimationsFromHtml -Uri $uri
    }
    else { Write-Error "Provide -StopId or -LineId" }
}

function Process-Stops {
    param($StopIds, $LineId, $Nonce, $Labels, $ThrottleLimit)
    
    $results = $StopIds | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
        $stopId = $_
        $uri = "https://aucorsa.es/wp-json/aucorsa/v1/estimations/stop?line=$using:LineId&current_line=$using:LineId&stop_id=$stopId&_wpnonce=$using:Nonce"
        try {
            $html = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
            $next = "No service"; $follow = "-"
            if ($html -notmatch 'ppp-no-estimations|Sin estimaci') {
                if ($html -match 'Pr&oacute;ximo autob&uacute;s: <strong[^>]*>([^<]+)<') { $next = $Matches[1] }
                if ($html -match 'Siguiente autob&uacute;s: <strong[^>]*>([^<]+)<') { $follow = $Matches[1] }
            }
            if ($next -ne "No service") {
                [PSCustomObject]@{ StopId = $stopId; NextBus = $next; FollowingBus = $follow }
            }
        }
        catch {}
    }
    
    $results | ForEach-Object {
        $name = if ($Labels.ContainsKey($_.StopId)) { $Labels[$_.StopId] } else { $_.StopId }
        $_ | Add-Member -NotePropertyName "StopName" -NotePropertyValue $name -PassThru
    } | Format-Table StopId, StopName, NextBus, FollowingBus -AutoSize | Out-Host
}

function Get-EstimationsFromHtml {
    param([string]$Uri)
    try {
        $html = Invoke-RestMethod -Uri $Uri -Method Get -WebSession $Global:AucorsaSession -ErrorAction Stop
        if ($html -match 'ppp-no-estimations|Sin estimaci') {
            return @([PSCustomObject]@{ LineNumber = "?"; LineRoute = "?"; NextBus = "No service"; FollowingBus = "-" })
        }
        $results = @()
        $matches = [regex]::Matches($html, '<div class="ppp-container">.*?</div></div></div>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        foreach ($m in $matches) {
            $block = $m.Value
            $lineNum = if ($block -match 'ppp-line-number[^>]*>(\d+)<') { $Matches[1] } else { "?" }
            $route = if ($block -match 'ppp-line-route[^>]*>([^<]+)<') { $Matches[1] } else { "?" }
            $next = if ($block -match 'Pr&oacute;ximo autob&uacute;s: <strong[^>]*>([^<]+)<') { $Matches[1] } else { "No service" }
            $follow = if ($block -match 'Siguiente autob&uacute;s: <strong[^>]*>([^<]+)<') { $Matches[1] } else { "-" }
            $results += [PSCustomObject]@{ LineNumber = $lineNum; LineRoute = $route; NextBus = $next; FollowingBus = $follow }
        }
        if ($results.Count -eq 0) {
            $next = if ($html -match 'Pr&oacute;ximo autob&uacute;s: <strong[^>]*>([^<]+)<') { $Matches[1] } else { "No service" }
            $follow = if ($html -match 'Siguiente autob&uacute;s: <strong[^>]*>([^<]+)<') { $Matches[1] } else { "-" }
            $results += [PSCustomObject]@{ LineNumber = "?"; LineRoute = "?"; NextBus = $next; FollowingBus = $follow }
        }
        return $results
    }
    catch { Write-Error "Failed: $_" }
}

# Main
if ($ListLines) {
    Get-AucorsaLines | Format-Table id, label -AutoSize
}
elseif ($StopId -or $LineId) {
    Get-AucorsaEstimation -StopId $StopId -LineId $LineId -ThrottleLimit $ThrottleLimit
}
else {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\Get-AucorsaEstimation.ps1 -StopId '105'" -ForegroundColor Yellow
    Write-Host "  .\Get-AucorsaEstimation.ps1 -LineId '706'" -ForegroundColor Yellow
    Write-Host "  .\Get-AucorsaEstimation.ps1 -ListLines" -ForegroundColor Yellow
}
