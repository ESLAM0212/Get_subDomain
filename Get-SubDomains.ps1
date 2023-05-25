param (
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$SubDomainList,

    [Parameter(Mandatory=$false)]
    [string]$OutFile,

    [Parameter(Mandatory=$false)]
    [switch]$ResolveIPv6
)

function Get-SubDomains {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [string]$SubDomainList,

        [Parameter(Mandatory=$false)]
        [string]$OutFile,

        [Parameter(Mandatory=$false)]
        [switch]$ResolveIPv6
    )

    $ErrorActionPreference = "Stop"

    try {
        Test-Path $SubDomainList -ErrorAction Stop | Out-Null

        foreach ($subDomain in Get-Content $SubDomainList) {
            try {
                if ($ResolveIPv6) {
                    $dnsResult = Resolve-DnsName "$subDomain.$Domain" -Type AAAA -ErrorAction Stop
                }
                else {
                    $dnsResult = Resolve-DnsName "$subDomain.$Domain" -Type A -ErrorAction Stop
                }

                foreach ($record in $dnsResult) {
                    if ($record.IPAddress) {
                        if ($record.Type -eq "A") {
                            $domainIP = $record.IPAddress
                            Write-Host -ForegroundColor Green "[Founded] $subDomain.$Domain : $domainIP"
                            if ($OutFile) {
                                "$subDomain.$Domain,$domainIP" | Out-File -Append $OutFile
                            }

                        }
                        elseif ($record.Type -eq "AAAA") {
                            $ipv6Address = $record.IPAddress
                            Write-Host -ForegroundColor Cyan "[IPv6] $subDomain.$Domain : $ipv6Address"
                            if ($OutFile) {
                                "$subDomain.$Domain,$ipv6Address" | Out-File -Append $OutFile
                            }
                        }
                    }
                }
            }
            catch {
                # Ignore resolution errors and continue with the next subDomain.
                continue
            }
        }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Host -ForegroundColor Red "[Error] Wordlist is not found"
    }
    catch {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }
}

# Call the function with the provided parameters
Get-SubDomains -Domain $Domain -SubDomainList $SubDomainList -OutFile $OutFile -ResolveIPv6:$ResolveIPv6
