#Variables
$location = "East US 2"
$rgName = "nsptest1-rg"
$objID = "90524a30-4993-4f68-be56-50fb5caa45fd" #object ID of the user currently logged on. 

# Connect to the Azure tenant
Connect-AzAccount

# Set the right subscription 
Set-AzContext -Subscription "c83ba7df-c127-4f6a-9550-505733e3e165"

# Register the Microsoft.Network resource provider
Register-AzResourceProvider -ProviderNamespace Microsoft.Network

# Install the PowerShell module required for this. 
Install-Module -Name Az.Network -RequiredVersion 7.7.1-preview -AllowPrerelease

# Create a resource group
$rg = New-AzResourceGroup -Name $rgName -Location $location

# Create a key vault
$keyVault = New-AzKeyVault -Name "demo-keyvault-$(Get-Random)" -ResourceGroupName $rg.ResourceGroupName -Location $location

# Create two storage accounts 
$storage1 = New-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name "storage$(Get-random)" -Location $location -SkuName "Standard_LRS" -Kind "StorageV2" -AssignIdentity
$storage2 = New-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name "storage$(Get-random)" -Location $location -SkuName "Standard_LRS" -Kind "StorageV2" -AssignIdentity

# Create a network security perimeter
$demoNSP = New-AzNetworkSecurityPerimeter -name "demo1-nsp" -location $location -ResourceGroupName $rg.ResourceGroupName

## Enable logging on the NSP. 

# Create a new profile
$demoNSPProfile = New-AzNetworkSecurityPerimeterProfile -name "nsp-profile" -ResourceGroupName $rg.ResourceGroupName -SecurityPerimeterName $demoNSP.Name

# Associate KeyVault with the created profile
$nspAkvAsc = New-AzNetworkSecurityPerimeterAssociation -ResourceGroupName $rg.ResourceGroupName -Name "nspAkvAsc" -SecurityPerimeterName $demoNSP.Name -AccessMode "Learning" -ProfileId $demoNSPProfile.id -PrivateLinkResourceId $keyVault.ResourceId

# Associate Storage1 with the created profile
$nspStor1Asc = New-AzNetworkSecurityPerimeterAssociation -ResourceGroupName $rg.ResourceGroupName -Name "nspStor1Asc" -SecurityPerimeterName $demoNSP.Name -AccessMode "Learning" -ProfileId $demoNSPProfile.id -PrivateLinkResourceId $storage1.Id

# Enable purge protection on AKV
Update-AzKeyVault -ResourceGroupName $rg.ResourceGroupName -VaultName $keyVault.VaultName -EnablePurgeProtection

# Create a key on AKV
New-AzRoleAssignment -ObjectId $objID -RoleDefinitionName "Key Vault Crypto Service Encryption User" -Scope $keyVault.ResourceId
New-AzRoleAssignment -ObjectId $storage1.Identity.PrincipalId -RoleDefinitionName "Key Vault Crypto Service Encryption User" -Scope $keyVault.ResourceId
Start-sleep -seconds 30 # wait for 30 seconds to make sure the roles are created
$keyName = Add-AzKeyVaultKey -VaultName $keyVault.VaultName -Name "storage-key1" -KeyType RSA -Size 4096 -Destination Software

# Switch the storage account to use CMK 
Set-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -AccountName $storage1.StorageAccountName -KeyvaultEncryption -KeyVaultUri $keyVault.VaultUri -KeyName $keyName.Name -KeyVersion ""

# Update the association to enforce the access mode
Update-AzNetworkSecurityPerimeterAssociation -ResourceGroupName $rg.ResourceGroupName -Name $nspAkvAsc.Name -SecurityPerimeterName $demoNSP.Name -AccessMode "Enforced" #AKV
Update-AzNetworkSecurityPerimeterAssociation -ResourceGroupName $rg.ResourceGroupName -Name $nspStor1Asc.Name -SecurityPerimeterName $demoNSP.Name -AccessMode "Enforced" #storage1

# Associate Storage2 with the above created profile
#$nspAkvAsc = New-AzNetworkSecurityPerimeterAssociation -ResourceGroupName $rg.ResourceGroupName -Name "nspStor2Asc" -SecurityPerimeterName $demoNSP.Name -AccessMode "Learning" -ProfileId $demoNSPProfile.id -PrivateLinkResourceId $storage2.Id

