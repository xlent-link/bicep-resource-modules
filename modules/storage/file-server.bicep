// ----------------------------------------------------------------------------
// FILE SERVER
// TODO: Cost reduction, https://learn.microsoft.com/en-us/azure/storage/common/storage-plan-manage-costs#understand-the-full-billing-model-for-azure-blob-storage
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The name of the storage account')
param name string

@description('If set, a AD group that can access the blob containers')
param adminGroupObjectId string

// Storage account
resource fileServer 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    isSftpEnabled: true
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
  }
}

var blobDataContribute = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
resource fileServerPermissions 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(fileServer.id, adminGroupObjectId, blobDataContribute)
  scope: fileServer
  properties: {
    principalId: adminGroupObjectId
    principalType: 'Group'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', blobDataContribute)
  }
}
