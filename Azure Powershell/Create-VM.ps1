<# 
    .SYNOPSIS
    For help, run get-help Create-VM.ps1

    .EXAMPLE
    $vmList = @(
        $(New-Object PSObject -Property @{Name = "vm-adds01-aue"; Size = "Standard_DS1_v2"; Vnet = "vn-main-aue"; Subnet = "snet-adds-aue"; IP = "10.0.0.5"; ResourceGroup = "rg-network-aue" }),
        $(New-Object PSObject -Property @{Name = "vm-ca01-aue"; Size = "Standard_DS1_v2"; Vnet = "vn-main-aue"; Subnet = "snet-srv-aue"; IP = "10.0.0.69"; ResourceGroup = "rg-srv-aue" })
        )
    .\Create-VM.ps1 -List $vmList -Location "australiaeast" -Credential (Get-Credential) -Verbose
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $True)]
    [PSOBject] $List,
    [parameter(Mandatory = $true)]    
    [string] $Location,
    [parameter(Mandatory = $true)]    
    [PSCredential] $Credential
)

# check if logged into AZ, if not, login
$azAccountTest = (Get-AZContext -ErrorAction SilentlyContinue).count
if ($azAccountTest -eq 0) {
    Write-Host 'Please Log in to Azure Account'
    Connect-AzAccount
}

# deploy each VM
foreach ($vm in $vmList) {
    $vmName = $vm.name
    $vmSize = $vm.Size
    $vmVnet = $vm.Vnet
    $vmSnet = $vm.Subnet
    $vmIP = $vm.IP
    $vmRg = $vm.ResourceGroup
    $vmNIC = $vmName + "-nic"
    $vmPIP = $vmname + "-pip"

    $rgChecker = (Get-AzResourceGroup -Name $vmRg -Location $Location -ErrorAction SilentlyContinue).count
    if ($rgChecker -eq 0) {
        Write-Host "Resource group '$vmRg' does not exist."
        break
    }

    $vnetConfig = Get-AZVirtualNetwork -Name $vmVnet -ErrorAction SilentlyContinue
    if (($vnetConfig).count -eq 0 ){
        Write-Host "Virtual Network '$vmVnet' does not exist."
        Stop-Transcript
        break 
    }

    $snetID = ($vnetConfig.Subnets | Where-Object Name -eq $vmSnet).id
    $pipConfig = New-AZPublicIpAddress -Name $vmPIP -ResourceGroupName $vmRg -Location $Location -AllocationMethod Dynamic
    $nicConfig = New-AZNetworkInterface -Name $vmNIC -ResourceGroupName $vmRg -Location $Location -SubnetId  $snetID -PublicIpAddressId $pipConfig.Id -PrivateIpAddress $vmIP
    
    $vmConfig = New-AZVMConfig -VMName $vmname -VMSize $vmSize
    $vmConfig = Set-AZVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmname -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
    $vmConfig = Add-AZVMNetworkInterface -VM $vmConfig -Id $nicConfig.Id
    $vmConfig = Set-AZVMSourceImage -VM $vmConfig -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest
    $vmConfig = Set-AZVMBootDiagnostic -Disable -VM $vmConfig
    Write-Host "Creating vm '$vmname' in resourcegroup '$vmRg' - VM Size '$vmSize' VM IP '$vmIP'"
    New-AZVM -ResourceGroupName $vmRg -Location $Location -VM $vmConfig -Verbose
}
