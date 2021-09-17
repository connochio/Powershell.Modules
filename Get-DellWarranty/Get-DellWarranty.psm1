Function Global:Get-DellWarranty {
    
    Param(
          [Switch] $Api,
          [Switch] $Brand,  
          [String] $ServiceTag = ((Get-WmiObject -Class "Win32_Bios").SerialNumber),
          [Switch] $Show,
          [Switch] $Full
         )

    if ($Api -ne $true){
        
        if ((Test-Path "$env:appdata\Microsoft\Windows\PowerShell\DellKey.txt")-ne $true){
            Write-Host "Please run 'Get-DellWarranty -Api' to provide Dell API Key (Missing)" -ForegroundColor White -BackgroundColor Red
            }
        if ((Test-Path "$env:appdata\Microsoft\Windows\PowerShell\DellSec.txt")-ne $true){
            Write-Host "Please run 'Get-DellWarranty -Api' to provide Dell API Secret (Missing)" -ForegroundColor White -BackgroundColor Red
            }
        else {

            if($ServiceTag -ne $(Get-WmiObject -Class "Win32_Bios").SerialNumber){$Show = $true}
            $ApiKey = Get-Content "$env:appdata\Microsoft\Windows\PowerShell\DellKey.txt"
            $ApiSecret = Get-Content "$env:appdata\Microsoft\Windows\PowerShell\DellSec.txt"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $Auth = Invoke-WebRequest "https://apigtwb2c.us.dell.com/auth/oauth/v2/token?client_id=${ApiKey}&client_secret=${ApiSecret}&grant_type=client_credentials" -Method Post
            $AuthSplit = $Auth.Content -split('"')
            $AuthKey = $AuthSplit[3]

            #$ServiceTag = $(Get-WmiObject -Class "Win32_Bios").SerialNumber

            $body = "?servicetags=" + $ServiceTag + "&Method=Get"

            $response = Invoke-WebRequest -uri https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements${body} -Headers @{"Authorization"="bearer ${AuthKey}";"Accept"="application/json"}
            $content = $response.Content | ConvertFrom-Json

            $WarrantyEndDateRaw = (($content.entitlements.endDate).split("T"))[-2]
            $WarrantyEndDate = [datetime]::ParseExact($WarrantyEndDateRaw, "yyyy-MM-dd", $null)
            $WarrantyStartDateRaw = (($content.entitlements.startDate).split("T"))[-2]
            $WarrantyStartDate = [datetime]::ParseExact($WarrantyStartDateRaw, "yyyy-MM-dd", $null)
            $WarrantyLevel = ($content.entitlements.serviceLevelDescription)[-1]
            $ShipDateRaw = (($content.shipDate).split("T"))[0]
            $ShipDate = [datetime]::ParseExact($ShipDateRaw, "yyyy-MM-dd", $null)
            $Model = $content.systemDescription

            if ($full -eq $true){
                $Show = $true}
                
            if ($Show -eq $true){
                $Today = get-date
                if ($Today -ge $WarrantyEndDate){Write-Host "`nWarranty has expired for $ServiceTag ($Model) " -ForegroundColor White -BackgroundColor Red}
                    Write-Host "`nThe machine's warranty started:" -NoNewline
                    Write-Host " $WarrantyStartDate" -ForegroundColor Cyan
                    Write-Host "The machine's warranty ends:" -NoNewline
                    if ($Today -le $WarrantyEndDate){Write-Host " $WarrantyEndDate" -ForegroundColor Cyan} else {Write-Host " $WarrantyEndDate " -ForegroundColor Red}
                    Write-Host "The current support level is:" -NoNewline
                    Write-Host " $WarrantyLevel`n" -ForegroundColor Cyan
                    if ($Full -eq $true){
                        Write-Host "The model is:"-NoNewline
                        Write-Host " $Model" -ForegroundColor Cyan
                        Write-Host "The ship date is:" -NoNewline
                        Write-Host " $ShipDate `n" -ForegroundColor Cyan
                        }
                    
                    }
        
            if ($Brand){
                if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") -ne $true){Write-Host "`nYou need use an elevated PowerShell window for -Brand to work`n" -ForegroundColor White -BackgroundColor Red}
                else {
        
                    $registryPath = "HKLM:\SOFTWARE\DELL\WARRANTY"
                    If (-NOT (Test-Path $registryPath)) {
                        New-Item $registryPath | Out-Null
                        }

                    New-ItemProperty -Path $registryPath -Name 'WarrantyStartDate' -Value $WarrantyStartDate -PropertyType ExpandString -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name 'WarrantyEndDate' -Value $WarrantyEndDate -PropertyType ExpandString -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name 'WarrantySupportLevel' -Value $WarrantyLevel -PropertyType ExpandString -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name 'Model' -Value $Model -PropertyType ExpandString -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name 'OriginalShipDate' -Value $ShipDate -PropertyType ExpandString -Force | Out-Null
                    New-ItemProperty -Path $registryPath -Name 'ServiceTag' -Value $ServiceTag -PropertyType ExpandString -Force | Out-Null
                }
            }
        }
    }
    else { 
        Read-Host -Prompt "`nPlease provide API Key" | Out-File $env:appdata\Microsoft\Windows\PowerShell\DellKey.txt -Force
        Read-Host -Prompt "`nNow please provide API Secret" | Out-File $env:appdata\Microsoft\Windows\PowerShell\DellSec.txt -Force
        Write-Host "`nYou can now run this with -Brand and -ServiceTag to get warranty information" -ForegroundColor Green
        Write-Host "If you need to change the API Key, please run 'Get-DellWarranty -Api' again`n" -ForegroundColor Green
    }
}
