# Set Variables for the commands
# Destination image resource group name
$imageResourceGroup = '<Image Resource Group>'
# Azure region supported for AIB
$location = '<Location>'
# Get the subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id

# Set Shared Image Gallery information
# Azure Compute Gallery (Previously SIG) Resource Group
$acgResourceGroup = '<ACG Resource Group>'

# Get the PowerShell modules
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

# Start by creating the Resource Group for the Managed Identity
New-AzResourceGroup -Name $imageResourceGroup -Location $location

# Create the user assigned Managed Identity
# Use current time to verify names are unique
[int]$timeInt = $(Get-Date -UFormat '%s')
$imageRoleDefName = "Azure Image Builder Image Def $timeInt"
$identityName = "myIdentity$timeInt"

# Create the User Identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

# Assign the identity resource and principle ID's to a variable
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

# Assign permissions for identity to distribute images
# downloads a .json file with settings, update with subscription settings
$myRoleImageCreationUrl = 'https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json'
$myRoleImageCreationPath = ".\myRoleImageCreation.json"
# Download the file
Invoke-WebRequest -Uri $myRoleImageCreationUrl -OutFile $myRoleImageCreationPath -UseBasicParsing

# Update the file
$Content = Get-Content -Path $myRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $acgResourceGroup
$Content = $Content -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName
$Content | Out-File -FilePath $myRoleImageCreationPath -Force

# Create the Role Definition
New-AzRoleDefinition -InputFile $myRoleImageCreationPath


# Grant the Role Definition to the Image Builder Service Principle at the ACG
$RoleAssignParams = @{
  ObjectId = $identityNamePrincipalId
  RoleDefinitionName = $imageRoleDefName
  Scope = "/subscriptions/$subscriptionID/resourceGroups/$acgResourceGroup"
}
New-AzRoleAssignment @RoleAssignParams


# Verify Role Assignment
Get-AzRoleAssignment -ObjectId $identityNamePrincipalId | Select-Object DisplayName,RoleDefinitionName, Scope