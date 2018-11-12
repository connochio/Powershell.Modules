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