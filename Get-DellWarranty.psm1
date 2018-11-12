Function Global:Get-DellWarranty {
    
    Param(
          [Switch] $Api,
          [Switch] $Brand,  
          [String] $ServiceTag = $(Get-WmiObject -Class "Win32_Bios").SerialNumber,
          [Switch] $Show,
          [Switch] $Full
         )
            
    if ($Api -ne $true){
        
        if ((Test-Path "$env:appdata\Microsoft\Windows\PowerShell\DellAPI.txt")-ne $true){Write-Host "`nPlease run 'Get-DellWarranty -Api' to provide Dell API Key`n" -ForegroundColor White -BackgroundColor Red} 
        else {
            
            if($ServiceTag -ne $(Get-WmiObject -Class "Win32_Bios").SerialNumber){$Show = $true}
            
            $APIKey = Get-Content "$env:appdata\Microsoft\Windows\PowerShell\DellAPI.txt"
            $URI = "https://api.dell.com/support/assetinfo/v4/getassetwarranty/${ServiceTag}?apikey=${APIKey}"
            $Request = Invoke-RestMethod -URI $URI -Method GET
            $Warranties = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'}
            $AssetDetails = $Request.AssetWarrantyResponse.assetheaderdata

            $EndDate = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand EndDate
            $EndDateD = $EndDate.split("T") | select -First 1
            $EndDateT = [datetime]::ParseExact($EndDateD, "yyyy-MM-dd", $null)
            $StartDate = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand StartDate
            $StartDateC = $StartDate.split("T") | select -Last 2
            $StartDateD = $StartDateC.split("T") | select -First 1
            $Support = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand ServiceLevelDescription  | Select-Object -first 1
            $PrevSupport = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand ServiceLevelDescription  | Select-Object -skip 1
            $Device = $Request.AssetWarrantyResponse.ProductHeaderData | select -expand SystemDescription
            $Shipped = $Request.AssetWarrantyResponse.AssetHeaderData | select -expand ShipDate
            $ShippedD = $Shipped.split("T") | select -First 1
            $Family = $Request.AssetWarrantyResponse.ProductHeaderData | select -expand ProductFamily

        if ($full -eq $true){
            $Show -eq $true | Out-Null}

        if ($Show -eq $true){
            $Today = get-date
            if ($today -ge $EndDateT){Write-Host "`nWarranty has expired for $ServiceTag ($Device) " -ForegroundColor White -BackgroundColor Red}
            Write-Host "`nThe machine's warranty started:" -NoNewline
            Write-Host "  $StartDateD" -ForegroundColor Cyan
            Write-Host "The machine's warranty ends:" -NoNewline
            if ($today -le $EndDateT){Write-Host "     $EndDateD" -ForegroundColor Cyan} else {Write-Host "     $EndDateD " -ForegroundColor Red}
            Write-Host "The current support level is:" -NoNewline
            Write-Host "    $Support`n" -ForegroundColor Cyan
            if ($Full -eq $true){
                Write-Host "The model family is:" -NoNewline
                Write-Host "             $Family" -ForegroundColor Cyan
                Write-Host "The model is:"-NoNewline
                Write-Host "                    $Device" -ForegroundColor Cyan
                Write-Host "The ship date is:" -NoNewline
                Write-Host "                $ShippedD" -ForegroundColor Cyan
                if ($PrevSupport.count -ne 0){
                    $PrevSupportFirst = $PrevSupport | Select-Object -first 1
                    $PrevSupportRest = $PrevSupport | Select-Object -Skip 1
                    Write-Host "`nPrevious support levels:" -NoNewLine
                    Write-Host "         $PrevSupportFirst" -ForegroundColor DarkGray
                    if ($PrevSupportRest.count -ne 0){
                        ForEach($Level in $PrevSupportRest){
                            Write-Host "                                 $Level" -ForegroundColor DarkGray
                            }
                        }
                    }
                }
            Write-Host " "
            }
        

        if ($Brand){
            if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") -ne $true){Write-Host "`nYou need use an elevated PowerShell window for -Brand to work`n" -ForegroundColor White -BackgroundColor Red}
            else {
                $registryPath = "HKLM:\SOFTWARE\WARRANTY"
                If (-NOT (Test-Path $registryPath)) {
                    New-Item $registryPath | Out-Null
                    }

                New-ItemProperty -Path $registryPath -Name 'WarrantyStartDate' -Value $StartDateD -PropertyType ExpandString -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name 'WarrantyEndDate' -Value $EndDateD -PropertyType ExpandString -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name 'WarrantySupportLevel' -Value $Support -PropertyType ExpandString -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name 'Model' -Value $Device -PropertyType ExpandString -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name 'OriginalShipDate' -Value $ShippedD -PropertyType ExpandString -Force | Out-Null
                New-ItemProperty -Path $registryPath -Name 'ServiceTag' -Value $ServiceTag -PropertyType ExpandString -Force | Out-Null
                }
            }
        }
    }
    
    else { 
        Read-Host -Prompt "`nPlease provide API Key" | Out-File $env:appdata\Microsoft\Windows\PowerShell\DellAPI.txt -Force
        Write-Host "`nYou can now run this with -Brand and -ServiceTag to get warranty information" -ForegroundColor Green
        Write-Host "If you need to change the API Key, please run 'Get-DellWarranty -Api' again`n" -ForegroundColor Green
    }

}
# SIG # Begin signature block
# MIIIlAYJKoZIhvcNAQcCoIIIhTCCCIECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaEs3wx5yNrMG6yMbKMHFidT3
# RIGgggXaMIIF1jCCBL6gAwIBAgITOgANn8HaaYSyy+jgYwAAAA2fwTANBgkqhkiG
# 9w0BAQsFADBrMRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxIjAgBgoJkiaJk/IsZAEZ
# FhJzdGVwc3RvbmVzb2x1dGlvbnMxGDAWBgoJkiaJk/IsZAEZFghpbnRlcm5hbDEU
# MBIGA1UEAxMLSW50ZXJuYWwtQ0EwHhcNMTgwOTI1MDgwODMzWhcNMTkwOTI1MDgw
# ODMzWjBfMRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxIjAgBgoJkiaJk/IsZAEZFhJz
# dGVwc3RvbmVzb2x1dGlvbnMxDjAMBgNVBAMTBVVzZXJzMRIwEAYDVQQDEwlzaGls
# bGNvMDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDHcX+A3rwzjZPa
# mn7lEsjJkwD2EuDadzuG21dLmktHJ0qjntNx8nibZikJY9jmEdxaeB1cGjt1mqEC
# Yj/LfI98wOZkdHsYYlus7UKKUdynuj/97u8bxNf8JitOUYg977nAPx31UVRGMHPG
# 8KKteFJcr/xwYujiJyIpDITamGfr+Nins0x5asxoqyyoE3TA4XgIBPrfSG6GnKm9
# k3kP7BkXKNK9w9l7vcoG0KroAIbEg9gu+0K9DLU4RmuC/b6s46mnzS5BBHMip7RL
# 0p/qF6E0IbA0qbxuYK6noHw/rvKlPcFOnG2xM1oHvkw4YQkU+PJN1xqrrQC9dTxE
# zb3nN3NFAgMBAAGjggJ9MIICeTAlBgkrBgEEAYI3FAIEGB4WAEMAbwBkAGUAUwBp
# AGcAbgBpAG4AZzATBgNVHSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4Aw
# HQYDVR0OBBYEFDFodrdrK02BlgUHRuALM0/vlFGpMB8GA1UdIwQYMBaAFAHN59OR
# GUFZwXXNzY8nsvE/BZ7iMIHeBgNVHR8EgdYwgdMwgdCggc2ggcqGgcdsZGFwOi8v
# L0NOPUludGVybmFsLUNBLENOPWRlLTJrMTJhZC10Y2cwMSxDTj1DRFAsQ049UHVi
# bGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlv
# bixEQz1zdGVwc3RvbmVzb2x1dGlvbnMsREM9bG9jYWw/Y2VydGlmaWNhdGVSZXZv
# Y2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50
# MIHKBggrBgEFBQcBAQSBvTCBujCBtwYIKwYBBQUHMAKGgapsZGFwOi8vL0NOPUlu
# dGVybmFsLUNBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1T
# ZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXN0ZXBzdG9uZXNvbHV0aW9ucyxE
# Qz1sb2NhbD9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNh
# dGlvbkF1dGhvcml0eTA9BgNVHREENjA0oDIGCisGAQQBgjcUAgOgJAwic2hpbGxj
# bzAxQHN0ZXBzdG9uZXNvbHV0aW9ucy5sb2NhbDANBgkqhkiG9w0BAQsFAAOCAQEA
# I0XQBVBjxyj+qM6noGngo0S6GFSWJBGhrsjHPyNcAT0Gn0C9aHrBrMq8PN5cBcgD
# JczWb93o2BSw4+4K9tfL/hk+gtLqoM+kH/xZBsbi8MpBAV/h8XOB8jh67F2L/rh5
# ot138/+lEiaO+kjUc4+ohaYBORfxRsQVJnt1On1UjtjjLBdaPNL65A+xYND1WMnr
# 9H7dYce70ZlyNa8BcXX4tvuuV2J6zKTcdz/yDWEM7oPrmHOYVljbWM6EljV3wVIw
# zAojR5+FpYRRy20MW9LFWuVqyf76qgRaWcQpoo8/EZfp1pK7cy5g0zDk6SMoqCSr
# rZGxA8wn/H48JhCU/okcRTGCAiQwggIgAgEBMIGCMGsxFTATBgoJkiaJk/IsZAEZ
# FgVsb2NhbDEiMCAGCgmSJomT8ixkARkWEnN0ZXBzdG9uZXNvbHV0aW9uczEYMBYG
# CgmSJomT8ixkARkWCGludGVybmFsMRQwEgYDVQQDEwtJbnRlcm5hbC1DQQITOgAN
# n8HaaYSyy+jgYwAAAA2fwTAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUPboKCN6czBHMsrZE29T9
# vfWFh50wDQYJKoZIhvcNAQEBBQAEggEAxGopml8Xbu4VW8tTzZNLmowNCrrpBmtB
# 9CGmYhbi0cp1OfCWzJx36QYtzkTiMuaTu8b/I3XinU2v5tAgY7TplqrdTMWfYWmU
# coPnKvM30FF+ZtAVGThj1niX1ScmyfIzm0XMUv+kOe7O55xn8V9yP7+LXLdznc6D
# zCoUIHoNw3/VJY/3XwRJ+Pq9SEwO7IDUeMxWcftm+QUVcAG48y110Jx52EySDQly
# uGZHxV1gFPcZ+XFwSozVBYLsymGYvlMdQn3azR7+6WX5eOzjlWzTRtG0iB8V5L9B
# UaA/IWaEj0I9Vj7wkI72D26eCdpxgHjQeMZbI884gGVaFeLoqiiNGg==
# SIG # End signature block
