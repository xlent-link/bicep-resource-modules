// ----------------------------------------------------------------------------
// KEY VAULT for site
// ----------------------------------------------------------------------------

@description('The Azure location. Only specify if not equal to the location of the current resource group.')
param location string = resourceGroup().location

@description('The name of the resource the key vault is for')
param siteName string

@description('The managed identity of the resource, e.g. function app ServicePrincipal')
param principalId string

@description('If set, an admin AD group id with access to this key vault')
param keyVaultGroupObjectId string = ''

// ----------------------------------------------------------------------------
// KEY VAULT
// ----------------------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: '${siteName}-keyvault'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: false
  }
}

var keyVaultSecretsAdminRole = '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator

// Access for site principal
resource kvFunctionAppPermissions 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(keyVault.id, siteName, keyVaultSecretsAdminRole)
  scope: keyVault
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsAdminRole)
  }
}

// Access for admin group
resource kvAdminPermissions 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (length(keyVaultGroupObjectId) != 0) {
  name: guid(keyVault.id, keyVaultGroupObjectId, keyVaultSecretsAdminRole)
  scope: keyVault
  properties: {
    principalId: keyVaultGroupObjectId
    principalType: 'Group'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsAdminRole)
  }
}
