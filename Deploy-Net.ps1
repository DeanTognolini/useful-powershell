<# 
    .SYNOPSIS
    For help, run get-help Deploy-Net.ps1

    .EXAMPLE
    .\Deploy-Net.ps1 -IP "192.168.10.50" -PrefixLength "24" -DefaultGateway "192.168.10.1" -DNS "127.0.0.1"
#>
[CmdletBinding()]
# parameters
param (
    [parameter(Mandatory = $true)]    
    [string] $IP,
    [parameter(Mandatory = $true)]    
    [string] $PrefixLength,
    [parameter(Mandatory = $true)]    
    [string] $DefaultGateway,
    [parameter(Mandatory = $true)]    
    [string] $DNS
)

# find the relevant network interface
$NetIndex = Get-NetAdapter | Where-Object {$_.Status -eq "up"}  | Select-Object -First 1 -ExpandProperty Name

# configure network settings
New-NetIPAddress `
    -InterfaceAlias $NetIndex `
    -AddressFamily "IPv4" `
    -IPAddress $IP `
    -PrefixLength $PrefixLength `
    -DefaultGateway $DefaultGateway

Set-DnsClientServerAddress -ServerAddresses $DNS -InterfaceAlias $NetIndex