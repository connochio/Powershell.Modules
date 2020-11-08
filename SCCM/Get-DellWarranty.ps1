Param (
    [String]$ApiKey,
    [String]$ApiSecret
)

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

if(((Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer) -notlike "Dell*"){Exit 1}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Auth = Invoke-WebRequest "https://apigtwb2c.us.dell.com/auth/oauth/v2/token?client_id=${ApiKey}&client_secret=${ApiSecret}&grant_type=client_credentials" -Method Post -UseBasicParsing
$AuthSplit = $Auth.Content -split('"')
$AuthKey = $AuthSplit[3]

if($AuthKey -eq $null){Exit 2}

$ServiceTag = $(Get-WmiObject -Class "Win32_Bios").SerialNumber

$body = "?servicetags=" + $ServiceTag + "&Method=Get"

$response = Invoke-WebRequest -uri https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements${body} -Headers @{"Authorization"="bearer ${AuthKey}";"Accept"="application/json"} -UseBasicParsing
if($response -eq $null){Exit 2}
$content = $response.Content | ConvertFrom-Json

$WarrantyEndDate = [datetime]::ParseExact(((($content.entitlements.endDate).split("T"))[-2]), "yyyy-MM-dd", $null).ToString('dd/MM/yyyy')
$WarrantyStartDate = [datetime]::ParseExact(((($content.entitlements.startDate).split("T"))[-2]), "yyyy-MM-dd", $null).ToString('dd/MM/yyyy')
$WarrantyLevel = ($content.entitlements.serviceLevelDescription)[-1]
$ShipDate = [datetime]::ParseExact(((($content.shipDate).split("T"))[-2]), "yyyy-MM-dd", $null).ToString('dd/MM/yyyy')
$Model = $content.systemDescription
$Uid = $content.id

    $registryPath = "HKLM:\SOFTWARE\Dell\WARRANTY"
            If (-NOT (Test-Path $registryPath)) {
                New-Item $registryPath -Force | Out-Null
                }

            New-ItemProperty -Path $registryPath -Name 'WarrantyStartDate' -Value $WarrantyStartDate -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name 'WarrantyEndDate' -Value $WarrantyEndDate -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name 'WarrantySupportLevel' -Value $WarrantyLevel -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name 'Model' -Value $Model -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name 'OriginalShipDate' -Value $ShipDate -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name 'ServiceTag' -Value $ServiceTag -PropertyType ExpandString -Force | Out-Null
            New-ItemProperty -Path $registryPath -Name 'DellId' -Value $Uid -PropertyType ExpandString -Force | Out-Null
