//Update each param for your environment
//Name of the template
param imageTemplateName string = '<Image Template Name>'
//URI of the Image Builder Managed Identity
param imageBuilderID string = '<Image Builder ID>'
//Set the build timeout, factor in replication time for SIG dsf
param buildTimeOut int = 60
//Path to the PowerShell installation file
param installScript string = '<URI to PowerShell Install File>'
//URI to the Shared Image Gallery
param sigImageDef string = '<URI to SIG Resource ID>'

//Update <SAS to Zip Archive> with SAS URI to zip archive
//Located in PowerShell GetArchive section

param location string = resourceGroup().location

resource aib 'Microsoft.VirtualMachineImages/imageTemplates@2019-05-01-preview' = {
  name: imageTemplateName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { 
      '${imageBuilderID}':{}
  }
  }
  properties: {
    buildTimeoutInMinutes: buildTimeOut
    vmProfile: {
      vmSize: 'Standard_B2ms'
      osDiskSizeGB: 127
    }
    source: {
      type: 'PlatformImage'
      publisher: 'MicrosoftWindowsDesktop'
      offer: 'Windows-10'
      sku: '21h1-evd'
      version: 'latest'
    }
    customize: [
      {
        type: 'PowerShell'
        name: 'GetAZCopy'
        inline: [
          'New-Item -Type Directory -Path \'c:\\\' -Name temp'
          'invoke-webrequest -uri \'https://aka.ms/downloadazcopy-v10-windows\' -OutFile \'c:\\temp\\azcopy.zip\''
          'Expand-Archive \'c:\\temp\\azcopy.zip\' \'c:\\temp\''
          'copy-item \'C:\\temp\\azcopy_windows_amd64_*\\azcopy.exe\\\' -Destination \'c:\\temp\''
        ]
      }
      {
        type: 'PowerShell'
        name: 'GetArchive'
        inline: [
          'c:\\temp\\azcopy.exe copy <SAS to Zip Archive> c:\\temp\\software.zip'
          'Expand-Archive \'c:\\temp\\software.zip\' c:\\temp'
        ]
      }
      {
        type: 'PowerShell'
        runElevated: true
        name: 'RunPoShInstall'
        scriptUri: installScript
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: sigImageDef
        runOutputName: 'win10Client'
        artifactTags: {
          source: 'azureVmImageBuilder'
          baseosimg: 'win10Multi'
        }
        replicationRegions: [
          'EastUS'
        ]
      }
    ]
  }
}
