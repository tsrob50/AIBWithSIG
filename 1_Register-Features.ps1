# Commands below are from 
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-powershell

# Log In
Connect-AzAccount

# View current subscription
Get-AzContext

# Set subscription 
Set-AzContext

# Register resource providers if not already registered
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute, Microsoft.KeyVault, Microsoft.Storage, Microsoft.VirtualMachineImages |
  Where-Object RegistrationState -ne Registered |
    Register-AzResourceProvider





