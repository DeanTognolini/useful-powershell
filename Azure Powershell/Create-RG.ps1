<# 
    .SYNOPSIS
    For help, run get-help Create-RG.ps1

    .EXAMPLE
    .\Create-RG.ps1 -rgPrefix "rg" -rgLocation "australiaeast" -LocShortName "aue" -Verbose
#>
[CmdletBinding()]
# parameters
param (
    [parameter(Mandatory = $true)]    
    [string] $rgPrefix,
    [parameter(Mandatory = $true)]    
    [string] $rgLocation,
    [parameter(Mandatory = $true)]    
    [string] $LocShortName
)

# check if logged into AZ, if not, login
$azAccountTest = (Get-AZContext -ErrorAction SilentlyContinue).count
if ($azAccountTest -eq 0) {
    Write-Host 'Please Log in to Azure Account'
    Connect-AzAccount
}

$rgs = @(
    '-adds-',
    '-network-',
    '-mgmt-',
    '-srv-',
    '-wks-'
)

# create new resource groups
foreach ($rg in $rgs) {
    $rgName = $rgPrefix + $rg + $LocShortName
    $rgTest = (Get-AzResourceGroup -Name $rgName -Location $rgLocation -ErrorAction SilentlyContinue).count
    if ($rgTest -eq 0) {
        Write-Host "New resource group $rgName in $rgLocation has been created."
        New-AzResourceGroup -Name $rgName -Location $rgLocation
    }
    else {
        Write-Host "$rgName already exists, skipping creation."
    }
}