#User customizable variables#
$netsnmp_install_dir = "$env:PROGRAMFILES\Net-SNMP" #Final install directory of Net-SNMP.
$netsnmp_archive = "$psscriptroot\netsnmp-5.9.4-openssl-3.5.1-win64.zip" #Filename of the Net-SNMP archive. Set to the directory the script.
#############################

#Requires -RunAsAdministrator

#Verify if the Net-SNMP archive exists. If it doesn't, terminate the script.
if (Test-Path -Path $netsnmp_archive) {
    Write-Host 'Net-SNMP archive located.'
}
else {
    Write-Host "ERROR: Net-SNMP archive missing. Unable to continue." -ForegroundColor Red
    Write-Host "Please verify $netsnmp_archive exists." -ForegroundColor Red
    exit
}

#Search for existing Net-SNMP services (upgrades). If they already exist, remove them. Not doing this will prevent a clean upgrade.
$service_netsnmp = Get-Service -Name 'Net-SNMP Agent' -ErrorAction SilentlyContinue
$service_netsnmptrap = Get-Service -Name 'Net-SNMP Trap Handler' -ErrorAction SilentlyContinue
if ($service_netsnmp) {
    Write-Host 'Removing Net-SNMP Agent service.'
    Stop-Service $service_netsnmp
    Remove-Service $service_netsnmp.Name
}
if ($service_netsnmptrap) {
    Write-Host 'Removing Net-SNMP Trap Handler service.'
    Stop-Service $service_netsnmptrap
    Remove-Service $service_netsnmptrap.Name
}

#Attempt to remove previous installation of Net-SNMP if it exists. Does not delete 'etc' or 'snmp' directories as these contain settings data.
if (Test-Path -Path $netsnmp_install_dir) {
    Write-Host 'Removing previous installation of Net-SNMP. Important settings will be retained for upgrade purposes.'
    Remove-Item -Path "$netsnmp_install_dir\bin" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$netsnmp_install_dir\include" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$netsnmp_install_dir\share" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$netsnmp_install_dir\temp" -Recurse -ErrorAction SilentlyContinue
}

#Extract archive, overwriting existing folders. 'etc' and 'snmp' folders are empty in the archive, so they won't overwrite our custom settings.
Write-Host 'Extracting Net-SNMP archive.'
Expand-Archive -Path $netsnmp_archive -DestinationPath $netsnmp_install_dir -Force

$dism_snmp = Get-WindowsCapability -Online -Name 'SNMP.Client~~~~0.0.1.0'
if ($dism_snmp.State -eq "NotPresent") {
    Write-Host 'Installing Windows SNMP Client. This is a Net-SNMP dependency. This may take a few minutes.'
    Add-WindowsCapability -Online -Name 'SNMP.Client~~~~0.0.1.0' #Use DISM to install Windows SNMP client.
}

#After installing/verifying the Windows SNMP Client, set the services to stopped and disabled.
Write-Host 'Stopping and disabling Windows SNMP services.'
$service_winsnmp = Get-Service -Name 'SNMP'
$service_winsnmptrap = Get-Service -Name 'SNMPTrap'
Stop-Service $service_winsnmp
Set-Service $service_winsnmp -StartupType Disabled
Stop-Service $service_winsnmptrap
Set-Service $service_winsnmptrap -StartupType Disabled

$create_netsnmp = @{
    Name = 'Net-SNMP Agent'
    BinaryPathname = "$netsnmp_install_dir\bin\snmpd.exe -service"
    DisplayName = 'Net-SNMP Agent'
    StartupType = 'Automatic'
    Description = 'SNMPv2c / SNMPv3 command responder from Net-SNMP'
}
$create_netsnmptrap = @{
    Name = 'Net-SNMP Trap Handler'
    BinaryPathName = "$netsnmp_install_dir\bin\snmptrapd.exe -service"
    DisplayName = 'Net-SNMP Trap Handler'
    StartupType = 'Disabled'
    Description = 'SNMPv2c / SNMPv3 trap/inform receiver from Net-SNMP'
}
Write-Host 'Creating Net-SNMP services.'
New-Service @create_netsnmp | Out-Null
New-Service @create_netsnmptrap | Out-Null

Write-Host 'Creating Net-SNMP firewall rules.'
Remove-NetFirewallRule -DisplayName '_Net-SNMP Agent (UDP)' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName '_Net-SNMP Trap Handler (UDP)' -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName '_Net-SNMP Agent (UDP)' -Program "$netsnmp_install_dir\bin\snmpd.exe" -Action Allow -Direction Inbound -Protocol UDP -LocalPort 161 | Out-Null
New-NetFirewallRule -DisplayName '_Net-SNMP Trap Handler (UDP)' -Program "$netsnmp_install_dir\bin\snmptrapd.exe" -Action Allow -Direction Inbound -Protocol UDP -LocalPort 162 | Out-Null

Write-Host 'Starting Net-SNMP Agent service.'
Start-Service 'Net-SNMP Agent'

Write-Host 'Net-SNMP installation complete.'
Write-Host

#Changelog
#2024-02-15 - AS - v1, Initial release.
#2024-07-23 - AS - v2, OpenSSL 3.3.1.
#2025-02-01 - AS - v3, OpenSSL 3.4.0.
#2025-07-22 - AS - v4, OpenSSL 3.5.1.
