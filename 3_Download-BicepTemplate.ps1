
# Start by downloading a template
# The template used is from the Azure Quick Start templates
# it creates a Windows image and outputs the finished image to a Managed IMage
# Set the template file path and the template file name
$win10AIBUrl = "https://raw.githubusercontent.com/tsrob50/AIBandSIG/main/AIB.bicep"
$win10AIB = "AIB.bicep"
#Test to see if the path exists.  Create it if not
if ((test-path .\Template) -eq $false) {
    new-item -ItemType Directory -name 'Template'
} 
# Confirm to overwrite file if it already exists
if ((test-path .\Template\$win10AIB) -eq $true) {
    $confirmation = Read-Host "Are you Sure You Want to Replace the Template?:"
    if ($confirmation -eq 'y' -or $confirmation -eq 'yes' -or $confirmation -eq 'Yes') {
        Invoke-WebRequest -Uri $win10AIBUrl -OutFile ".\Template\$win10AIB" -UseBasicParsing
    }
}
else {
    Invoke-WebRequest -Uri $win10AIBUrl -OutFile ".\Template\$win10AIB" -UseBasicParsing
}


# Update the parameter section of the AIB.bicep file under .\Template


# Set variables if not already defined
$imageResourceGroup = '<Image Resource Group>'
$imageTemplateName = '<Image Template Name>'


# Install Bicep if not already available
# follow one of the options in the link below to install Bicep
# https://github.com/Azure/bicep/blob/main/docs/installing.md

 # The following commands require the Az.ImageBuilder module
# Install the PowerShell module if not already installed
Get-Module -Name Az.ImageBuilder
Install-Module -name Az.ImageBuilder

# Run the Bicep deployment 
New-AzResourceGroupDeployment -name <Deployment Name> -ResourceGroupName $imageResourceGroup -TemplateFile .\Template\AIB.bicep 


# Verify the template
Get-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup |
Select-Object -Property Name, LastRunStatusRunState, LastRunStatusMessage, ProvisioningState, ProvisioningErrorMessage


# Start the Image Build Process
Start-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName


# Create a VM to test 
$Cred = Get-Credential 
$ArtifactId = (Get-AzImageBuilderRunOutput -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup).ArtifactId
New-AzVM -ResourceGroupName $imageResourceGroup -Image $ArtifactId -Name myWinVM01 -Credential $Cred -size Standard_D2_v2


# Remove the template deployment
remove-AzImageBuilderTemplate -ImageTemplateName $imageTemplateName -ResourceGroupName $imageResourceGroup





# Find the publisher, offer and Sku
# To use for the deployment template to identify 
# source marketplace images
# https://www.ciraltos.com/find-skus-images-available-azure-rm/
Get-AzVMImagePublisher -Location $location | where-object {$_.PublisherName -like "*win*"} | ft PublisherName,Location
$pubName = 'MicrosoftWindowsDesktop'
Get-AzVMImageOffer -Location $location -PublisherName $pubName | ft Offer,PublisherName,Location
# Set Offer to 'office-365' for images with O365 
# $offerName = 'office-365'
$offerName = 'windows-11'
Get-AzVMImageSku -Location $location -PublisherName $pubName -Offer $offerName | ft Skus,Offer,PublisherName,Location
$skuName = 'win10-21h2-avd'
Get-AzVMImage -Location $location -PublisherName $pubName -Skus $skuName -Offer $offerName
$version = '<version>'
Get-AzVMImage -Location $location -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version
