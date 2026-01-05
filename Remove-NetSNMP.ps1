# User customizable variables
$netsnmp_install_dir = "$env:PROGRAMFILES\Net-SNMP" # Final install directory of Net-SNMP.
#############################

#Requires -RunAsAdministrator

Write-Host 'Stopping Windows SNMP services.'
$service_winsnmp = Get-Service -Name 'SNMP' -ErrorAction SilentlyContinue
$service_winsnmptrap = Get-Service -Name 'SNMPTrap' -ErrorAction SilentlyContinue
if ($service_winsnmp) {Stop-Service $service_winsnmp}
if ($service_winsnmptrap) {Stop-Service $service_winsnmptrap}

$dism_snmp = Get-WindowsCapability -Online -Name 'SNMP.Client~~~~0.0.1.0'
if ($dism_snmp.State -eq "Installed") {
    Write-Host 'Removing Windows SNMP Client.'
    Remove-WindowsCapability -Online -Name “SNMP.Client~~~~0.0.1.0“
}

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

if (Test-Path -Path $netsnmp_install_dir) {
    Write-Host 'Removing installation of Net-SNMP. Important settings will be retained.'
    Remove-Item -Path "$netsnmp_install_dir\bin" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$netsnmp_install_dir\include" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$netsnmp_install_dir\share" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "$netsnmp_install_dir\temp" -Recurse -ErrorAction SilentlyContinue
}

Write-Host 'Removing firewall rules.'
Remove-NetFirewallRule -DisplayName '_Net-SNMP Agent (UDP)' -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName '_Net-SNMP Trap Handler (UDP)' -ErrorAction SilentlyContinue

Write-Host 'Windows SNMP Client and Net-SNMP have been removed.'
Write-Host

# Changelog
#2024-02-15 - AS - v1, Initial release.
#2025-01-04 - AS - v2, Minor changes.