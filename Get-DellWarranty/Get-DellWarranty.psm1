Function Global:Get-DellAssetInformation {
    
    Param(
          [Switch] $Api,
          [Switch] $Brand,  
          [String] $ServiceTag = $(Get-WmiObject -Class "Win32_Bios").SerialNumber,
          [Switch] $Show
         )
            
    if ($Api -ne $true){
        
        if ((Test-Path "$env:appdata\Microsoft\Windows\PowerShell\DellAPI.txt")-ne $true){Write-Host "`nPlease run 'Get-DellAssetInformation -Api' to provide Dell API Key"} 
        else {
            
            if($ServiceTag -ne $(Get-WmiObject -Class "Win32_Bios").SerialNumber){$Show = $true}
            
            $APIKey = Get-Content "$env:appdata\Microsoft\Windows\PowerShell\DellAPI.txt"
            $URI = "https://api.dell.com/support/assetinfo/v4/getassetwarranty/${ServiceTag}?apikey=${APIKey}"
            $Request = Invoke-RestMethod -URI $URI -Method GET
            $Warranties = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'}
            $AssetDetails = $Request.AssetWarrantyResponse.assetheaderdata

            $EndDate = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand EndDate
            $EndDateD = $EndDate.split("T") | select -First 1
            $StartDate = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand StartDate
            $StartDateC = $StartDate.split("T") | select -Last 2
            $StartDated = $StartDateC.split("T") | select -First 1
            $Support = $Request.AssetWarrantyResponse.assetentitlementdata | where {$_.ServiceLevelDescription -NE 'Dell Digitial Delivery' -and $_.ServiceLevelDescription -NE 'Collect and Return Support'} | select -expand ServiceLevelDescription
            $Device = $Request.AssetWarrantyResponse.ProductHeaderData | select -expand SystemDescription
            $Shipped = $Request.AssetWarrantyResponse.AssetHeaderData | select -expand ShipDate
            $ShippedD = $Shipped.split("T") | select -SkipLast 1

        if ($Show -eq $true){
            Write-Host "`nThis machine's warranty started: $StartDateD"
            Write-host "This machine's warranty ends:    $EndDateD"
            Write-Host "The support Level is:            $Support"
            }

        if ($Brand){
            if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") -ne $true){Write-Host "`nYou need use an elevated PowerShell window for -Brand to work"}
            else {
                $registryPath = "HKLM:\HARDWARE\WARRANTY"
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
        Read-Host -Prompt "Please provide API Key" | Out-File $env:appdata\Microsoft\Windows\PowerShell\DellAPI.txt -Force
        Write-Host "`nYou can now run this with -Brand and -ServiceTag to get warranty information `n"
        Write-Host "If you need to change the API Key, please run 'Get-DellAssetInformation -Api' again"
    }

}