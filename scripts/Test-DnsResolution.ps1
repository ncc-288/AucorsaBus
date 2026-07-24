<#
.SYNOPSIS
    Tests DNS resolution for AUCORSA domains

.EXAMPLE
    .\Test-DnsResolution.ps1
#>

Write-Host "=== Testing DNS Resolution ===" -ForegroundColor Cyan

$domains = @(
    "aucorsa.es",
    "www.aucorsa.es",
    "lightapi.aucorsa.es"
)

foreach ($domain in $domains) {
    Write-Host "`nDomain: $domain" -ForegroundColor Yellow
    
    try {
        $result = Resolve-DnsName -Name $domain -ErrorAction Stop
        
        Write-Host "  ✅ Resolved successfully" -ForegroundColor Green
        
        foreach ($record in $result) {
            if ($record.Type -eq "A") {
                Write-Host "  IPv4: $($record.IPAddress)" -ForegroundColor White
            } elseif ($record.Type -eq "AAAA") {
                Write-Host "  IPv6: $($record.IPAddress)" -ForegroundColor White
            } elseif ($record.Type -eq "CNAME") {
                Write-Host "  CNAME: $($record.NameHost)" -ForegroundColor Cyan
            }
        }
        
    } catch {
        Write-Host "  ❌ DNS resolution FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n💡 Note: If lightapi.aucorsa.es fails to resolve, that's why the phone can't access it." -ForegroundColor Yellow
