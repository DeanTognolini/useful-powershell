<# 
    .SYNOPSIS
    For help, run get-help Create-VN.ps1

    .EXAMPLE
    .\Create-VN.ps1 -rgName "rg-network-aue" -vnLocation "australiaeast" -LocShortName "aue" -vnPrefix "10.0" -Verbose
#>
[CmdletBinding()]
# parameters
param (
    [parameter(Mandatory = $true)]    
    [string] $rgName,
    [parameter(Mandatory = $true)]    
    [string] $vnLocation,
    [parameter(Mandatory = $true)]    
    [string] $LocShortName,
    [parameter(Mandatory = $true)]    
    [string] $vnPrefix
)

# check if logged into AZ, if not, login
$azAccountTest = (Get-AZContext -ErrorAction SilentlyContinue).count
if ($azAccountTest -eq 0) {
    Write-Host 'Please Log in to Azure Account'
    Connect-AzAccount
}

$vnRange = $vnPrefix + ".0.0/24"
$vnName = "vn-main-" + $LocShortName
$subnetsData = @(
    $(New-Object PSObject -Property @{Name = "snet-adds-" + $LocShortName; Range = $vnPrefix + ".0.0/27" }),
    $(New-Object PSObject -Property @{Name = "snet-wks-" + $LocShortName; Range = $vnPrefix + ".0.32/27" }),
    $(New-Object PSObject -Property @{Name = "snet-srv-" + $LocShortName; Range = $vnPrefix + ".0.64/27" })
)
$dnsServer = $vnPrefix + ".0.4"
$subnetsConfig = @()

foreach ($subnet in $subnetsData) {
    Write-Host "Declaring new Subnet '$($subnet.name)' with range '$($subnet.range)'"
    $snet = New-AZVirtualNetworkSubnetConfig -Name $subnet.name -AddressPrefix $subnet.range
    $subnetsConfig += $snet
}

$vnTest = (Get-AZVirtualNetwork -Name $vnName -ResourceGroupName $rgName -ErrorAction SilentlyContinue).count
if ($vnTest -eq 0) {
    Write-Host "Creating new virtual network  '$vnName' in '$rgName' resourcegroup."
    New-AZVirtualNetwork -Name $vnName -ResourceGroupName $rgName -Location $vnLocation -AddressPrefix $vnRange -Subnet $subnetsConfig -DnsServer $dnsServer
}
else {
    Write-Host "The follwoing virtual network '$vnName' already exists."
}