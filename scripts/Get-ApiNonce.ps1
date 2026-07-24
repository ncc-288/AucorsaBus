<#
.SYNOPSIS
    Gets a valid nonce from the AUCORSA API

.DESCRIPTION
    Fetches the main AUCORSA page and extracts the ajax_nonce value

.EXAMPLE
    $nonce = .\Get-ApiNonce.ps1
#>

try {
    $targetUrl = "https://aucorsa.es/"
    $response = Invoke-WebRequest -Uri $targetUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    
    if ($response.StatusCode -eq 200) {
        $nonceMatch = [regex]::Match($response.Content, '"ajax_nonce":"(.*?)"')
        
        if ($nonceMatch.Success) {
            $nonce = $nonceMatch.Groups[1].Value
            return $nonce
        } else {
            Write-Error "Could not extract nonce from response"
            return $null
        }
    }
} catch {
    Write-Error "Exception getting nonce: $_"
    return $null
}
